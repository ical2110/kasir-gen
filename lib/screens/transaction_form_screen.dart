import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:kasir_gen/models/transaction_item.dart';
import 'package:kasir_gen/models/service_price.dart';
import '../models/customer.dart';
import '../models/service.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';

class TransactionFormScreen extends StatefulWidget {
  // final Transaction? transaction; // Dihapus karena tidak ada lagi mode edit

  const TransactionFormScreen({super.key});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

// Helper class untuk mengelola state setiap baris item transaksi
class TransactionItemController {
  Service? selectedService;
  ServicePrice? selectedPrice;
  final TextEditingController quantityController;

  TransactionItemController()
      : quantityController = TextEditingController(text: '1');

  void dispose() {
    quantityController.dispose();
  }

  // Validasi sederhana untuk satu baris
  bool get isValid =>
      selectedService != null &&
      selectedPrice != null &&
      (int.tryParse(quantityController.text) ?? 0) > 0;
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Data
  List<Customer> _customers = [];
  List<Service> _services = [];

  // State Form
  Customer? _selectedCustomer;
  String? _selectedSource; // State untuk Drop Point
  final _notesController = TextEditingController();
  List<TransactionItemController> _itemControllers = [];
  double _totalAmount = 0.0;

  bool _isLoading = true; // Loading untuk data awal
  bool _isSaving = false; // Loading untuk proses simpan

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _selectedSource = 'Workshop'; // Nilai default
    // Tambahkan satu baris item secara default
    _addTransactionItem();
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      // Gunakan Future.wait untuk memuat data secara paralel agar lebih efisien
      final results = await Future.wait([
        _apiService.getCustomers(),
        _apiService.getServices(),
      ]);

      final customers = results[0] as List<Customer>;
      final services = results[1] as List<Service>;

      // Cek 'mounted' sebelum setState untuk menghindari error jika widget sudah di-dispose
      if (!mounted) return;

      // 1. Set state untuk daftar customers dan services terlebih dahulu.
      setState(() {
        _customers = customers;
        _services = services;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e')),
        );
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    }
  }

  void _addTransactionItem() {
    setState(() {
      final newItemController = TransactionItemController();
      newItemController.quantityController.addListener(_calculateTotal);
      _itemControllers.add(newItemController);
    });
  }

  void _removeTransactionItem(int index) {
    setState(() {
      _itemControllers[index].dispose();
      _itemControllers.removeAt(index);
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    double currentTotal = 0.0;
    for (var controller in _itemControllers) {
      final quantity = int.tryParse(controller.quantityController.text) ?? 0;
      final price = controller.selectedPrice?.price ?? 0.0;
      currentTotal += quantity * price;
    }
    setState(() {
      _totalAmount = currentTotal;
    });
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate() || _itemControllers.isEmpty) {
      return;
    }

    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pelanggan harus dipilih')),
      );
      return;
    }

    if (_selectedSource == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Drop point harus dipilih')),
      );
      return;
    }

    // Validasi setiap item
    if (_itemControllers.any((controller) => !controller.isValid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Pastikan semua layanan, harga, dan kuantitas terisi dengan benar.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Buat daftar TransactionItem dari controllers
      final List<TransactionItem> transactionItems =
          _itemControllers.map((controller) {
        final quantity = int.parse(controller.quantityController.text);
        final price = controller.selectedPrice!.price;
        return TransactionItem(
          serviceId: controller.selectedService!.id,
          serviceName: controller.selectedService!.name,
          priceId: controller.selectedPrice!.priceId,
          priceNotes: controller.selectedPrice!.notes,
          price: price,
          quantity: quantity,
          subtotal: quantity * price,
        );
      }).toList();

      final transactionData = Transaction(
        id: '', // ID akan dibuat oleh backend
        customerId: _selectedCustomer!.id,
        status: TransactionStatus.in_progress,
        totalAmount: _totalAmount,
        items: transactionItems,
        notes: _notesController.text,
        transactionSource: _selectedSource,
        customer: _selectedCustomer, // Sertakan objek customer lengkap
      );

      await _apiService.addTransaction(transactionData);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil disimpan!')),
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Transaksi'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Dropdown Pelanggan
                  DropdownButtonFormField<Customer>(
                    value: _selectedCustomer,
                    // Menampilkan item yang dipilih meskipun sudah tidak ada di daftar
                    items: _customers.map((customer) {
                      return DropdownMenuItem<Customer>(
                        value: customer,
                        child: Text(customer.name),
                      );
                    }).toList(),
                    hint: const Text('Pilih Pelanggan'),
                    onChanged: (value) {
                      setState(() => _selectedCustomer = value);
                    },
                    validator: (value) =>
                        value == null ? 'Pelanggan wajib dipilih' : null,
                    isExpanded: true,
                  ),
                  const SizedBox(height: 16),

                  // Dropdown Drop Point
                  DropdownButtonFormField<String>(
                    value: _selectedSource,
                    items: ['Workshop', 'Dibarbers', 'Antar-jemput']
                        .map((source) => DropdownMenuItem<String>(
                              value: source,
                              child: Text(source),
                            ))
                        .toList(),
                    hint: const Text('Pilih Drop Point'),
                    onChanged: (value) {
                      setState(() => _selectedSource = value);
                    },
                    validator: (value) =>
                        value == null ? 'Drop point wajib dipilih' : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Drop Point'),
                  ),
                  const SizedBox(height: 16),

                  // Daftar Item Layanan
                  ..._itemControllers.asMap().entries.map((entry) {
                    int index = entry.key;
                    TransactionItemController controller = entry.value;
                    return _buildTransactionItemRow(index, controller);
                  }).toList(),

                  const SizedBox(height: 16),

                  // Tombol Tambah Layanan
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Layanan'),
                    onPressed: _addTransactionItem,
                  ),

                  const SizedBox(height: 16),

                  // Catatan
                  TextFormField(
                    controller: _notesController,
                    decoration:
                        const InputDecoration(labelText: 'Catatan (Opsional)'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Total
                  ListTile(
                    title: const Text('Total Harga',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text(
                      'Rp ${_totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Simpan
                  _isSaving
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _saveTransaction,
                          child: const Text('Simpan'),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildTransactionItemRow(
      int index, TransactionItemController controller) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Layanan #${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                if (_itemControllers.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _removeTransactionItem(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const Divider(),
            DropdownButtonFormField<Service>(
              value: controller.selectedService,
              hint: const Text('Pilih Layanan'),
              items: _services.map((service) {
                return DropdownMenuItem<Service>(
                    value: service, child: Text(service.name));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  controller.selectedService = value;
                  controller.selectedPrice = null; // Reset harga
                  if (value != null && value.prices.isNotEmpty) {
                    controller.selectedPrice = value.prices.first;
                  }
                  _calculateTotal();
                });
              },
              validator: (v) => v == null ? 'Wajib' : null,
              isExpanded: true,
            ),
            const SizedBox(height: 12),
            if (controller.selectedService != null)
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<ServicePrice>(
                      value: controller.selectedPrice,
                      hint: const Text('Harga'),
                      items: controller.selectedService!.prices.map((price) {
                        return DropdownMenuItem<ServicePrice>(
                            value: price,
                            child: Text(price.notes ?? 'Rp ${price.price}'));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          controller.selectedPrice = value;
                          _calculateTotal();
                        });
                      },
                      validator: (v) => v == null ? 'Wajib' : null,
                      isExpanded: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                        controller: controller.quantityController,
                        decoration: const InputDecoration(labelText: 'Qty'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                            ? 'Qty > 0'
                            : null),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
