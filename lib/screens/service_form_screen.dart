import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/service.dart';
import '../models/service_price.dart';
import '../services/api_service.dart';

// Helper class untuk mengelola controller di setiap baris harga
class PriceControllers {
  final TextEditingController priceController;
  final String priceId;
  final String? notes;
  final DateTime? createdAt;

  PriceControllers({
    required this.priceId,
    ServicePrice? existingPrice,
  })  : notes = existingPrice?.notes,
        createdAt = existingPrice?.createdAt,
        priceController = TextEditingController(
          text: existingPrice?.price.toStringAsFixed(0) ?? '',
        );

  void dispose() {
    priceController.dispose();
  }
}

class ServiceFormScreen extends StatefulWidget {
  final Service? service; // Untuk mode edit nanti

  const ServiceFormScreen({super.key, this.service});

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService apiService = ApiService();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  final List<PriceControllers> _priceControllers = [];
  int _nextPriceNumber = 0;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service?.name);
    _descriptionController =
        TextEditingController(text: widget.service?.description);

    // Jika mode tambah, tambahkan satu baris harga kosong secara default
    if (widget.service == null) {
      _addPriceRow();
    } else {
      // Isi data harga jika dalam mode edit
      if (widget.service!.prices.isEmpty) {
        _addPriceRow(); // Tambah satu baris kosong jika layanan yang diedit belum punya harga
      } else {
        for (var price in widget.service!.prices) {
          _addPriceRow(existingPrice: price);
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (final controllers in _priceControllers) {
      controllers.dispose();
    }
    super.dispose();
  }

  void _addPriceRow({ServicePrice? existingPrice}) {
    setState(() {
      _priceControllers.add(
        PriceControllers(
          priceId: existingPrice?.priceId.isNotEmpty == true
              ? existingPrice!.priceId
              : _createPriceId(),
          existingPrice: existingPrice,
        ),
      );
    });
  }

  String _createPriceId() =>
      'price_${DateTime.now().microsecondsSinceEpoch}_${_nextPriceNumber++}';

  void _removePriceRow(int index) {
    setState(() {
      _priceControllers[index].dispose();
      _priceControllers.removeAt(index);
    });
  }

  Future<void> _saveService() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final isEditing = widget.service != null;

        // Buat daftar ServicePrice dari controllers
        final prices = _priceControllers.map((controllers) {
          return ServicePrice(
            // Harga disimpan sebagai array pada dokumen layanan, sehingga ID
            // varian harus tetap unik dan stabil saat layanan diperbarui.
            priceId: controllers.priceId,
            serviceId: widget.service?.id ?? '',
            notes: controllers.notes,
            price: double.tryParse(controllers.priceController.text) ?? 0.0,
            createdAt: controllers.createdAt,
          );
        }).toList();

        // Buat objek Service dari data form
        final serviceData = Service(
          id: widget.service?.id ?? '',
          name: _nameController.text,
          description: _descriptionController.text,
          prices: prices,
        );

        if (isEditing) {
          await apiService.updateService(serviceData);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Layanan berhasil diperbarui!')),
          );
        } else {
          await apiService.addService(serviceData);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Layanan baru berhasil disimpan!')),
          );
        }

        if (mounted) Navigator.pop(context, true); // Kirim sinyal refresh
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan layanan: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service == null ? 'Tambah Layanan' : 'Edit Layanan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Layanan'),
                validator: (value) =>
                    value!.isEmpty ? 'Nama layanan tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration:
                    const InputDecoration(labelText: 'Deskripsi (Opsional)'),
              ),
              const SizedBox(height: 24),
              Text('Daftar Harga',
                  style: Theme.of(context).textTheme.titleMedium),
              const Divider(),
              ..._priceControllers.asMap().entries.map((entry) {
                int index = entry.key;
                PriceControllers controllers = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controllers.priceController,
                          decoration: const InputDecoration(labelText: 'Harga'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (value) =>
                              value!.isEmpty ? 'Wajib diisi' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_priceControllers.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.red),
                          onPressed: () => _removePriceRow(index),
                        ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveService,
                      child: Text(widget.service == null ? 'Simpan' : 'Update'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
