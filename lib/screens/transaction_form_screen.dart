import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Data
  List<Customer> _customers = [];
  List<Service> _services = [];

  // State Form
  Customer? _selectedCustomer;
  Service? _selectedService;
  ServicePrice? _selectedPrice;
  final _quantityController = TextEditingController(text: '1');
  final _notesController = TextEditingController();
  double _totalAmount = 0.0;

  bool _isLoading = true; // Loading untuk data awal
  bool _isSaving = false; // Loading untuk proses simpan

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _quantityController.addListener(_calculateTotal);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
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

      // 2. Setelah state di atas diatur, baru jalankan logika untuk mode edit.
      // if (widget.transaction != null) {
      //   _initializeEditMode();
      // }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  // Fungsi terpusat untuk menangani perubahan pada dropdown layanan
  void _onServiceChanged(Service? newService) {
    setState(() {
      _selectedService = newService;
      _selectedPrice = null; // Reset harga saat layanan berubah

      if (newService != null && newService.prices.isNotEmpty) {
        // Jika tidak ditemukan atau bukan mode edit, pilih harga pertama sebagai default
        _selectedPrice = newService.prices.first;
      }
      _calculateTotal(); // Hitung ulang total setiap kali layanan atau harga berubah
    });
  }

  void _calculateTotal() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final price = _selectedPrice?.price ?? 0.0;
    setState(() {
      _totalAmount = quantity * price;
    });
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedCustomer == null ||
        _selectedService == null ||
        _selectedPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pelanggan, Layanan, dan Harga harus dipilih')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final transactionData = Transaction(
        id: '', // ID akan dibuat oleh backend
        customerId: _selectedCustomer!.id,
        serviceId: _selectedService!.id,
        priceId: _selectedPrice!.priceId, // Sertakan priceId saat menyimpan
        status:
            TransactionStatus.in_progress, // Selalu in_progress untuk data baru
        quantity: int.parse(_quantityController.text),
        totalAmount: _totalAmount,
        notes: _notesController.text,
        customer: _selectedCustomer, // Sertakan objek customer lengkap
        service: _selectedService, // Sertakan objek service lengkap
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

                  // Dropdown Layanan
                  DropdownButtonFormField<Service>(
                    value: _selectedService,
                    hint: const Text('Pilih Layanan'),
                    items: _services.map((service) {
                      return DropdownMenuItem<Service>(
                        value: service,
                        child: Text(service.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      _onServiceChanged(value);
                    },
                    validator: (value) =>
                        value == null ? 'Layanan wajib dipilih' : null,
                    isExpanded: true,
                  ),
                  const SizedBox(height: 16),

                  // Dropdown Harga (jika layanan punya > 1 harga)
                  if (_selectedService != null &&
                      _selectedService!.prices.length > 1)
                    DropdownButtonFormField<ServicePrice>(
                      value: _selectedPrice,
                      hint: const Text('Pilih Varian Harga'),
                      items: _selectedService!.prices.map((price) {
                        return DropdownMenuItem<ServicePrice>(
                          value: price,
                          child: Text(price.notes ?? 'Rp ${price.price}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPrice = value;
                          _calculateTotal();
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Harga wajib dipilih' : null,
                      isExpanded: true,
                    ),
                  if (_selectedService != null &&
                      _selectedService!.prices.length > 1)
                    const SizedBox(height: 16),

                  // Kuantitas
                  TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(labelText: 'Kuantitas'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Kuantitas wajib diisi';
                      if (int.tryParse(value) == null ||
                          int.parse(value) <= 0) {
                        return 'Masukkan angka yang valid';
                      }
                      return null;
                    },
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
}
