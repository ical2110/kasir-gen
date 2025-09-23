import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/api_service.dart';

class CustomerFormScreen extends StatefulWidget {
  final Customer? customer; // Nullable, untuk membedakan mode Tambah dan Edit

  CustomerFormScreen({this.customer});

  @override
  _CustomerFormScreenState createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService apiService = ApiService();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _alamatController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name);
    _phoneController = TextEditingController(text: widget.customer?.phone);
    _alamatController = TextEditingController(text: widget.customer?.alamat);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final isEditing = widget.customer != null;

        // Membuat objek customer dari data form
        final customerData = Customer(
          // Gunakan ID yang ada jika edit, atau buat ID baru jika perlu (tergantung backend)
          // Di sini kita asumsikan backend menangani ID untuk customer baru.
          // Untuk edit, kita harus mengirim ID yang sudah ada.
          id: widget.customer?.id ?? '',
          name: _nameController.text,
          phone: _phoneController.text,
          alamat: _alamatController.text,
        );

        if (isEditing) {
          await apiService.updateCustomer(customerData);
          if (!mounted) return;
          // Tampilkan pesan sukses
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pelanggan berhasil diperbarui!')),
          );
        } else {
          await apiService.addCustomer(customerData);
          if (!mounted) return;
          // Tampilkan pesan sukses
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pelanggan baru berhasil disimpan!')),
          );
        }

        // Kembali ke halaman sebelumnya dan kirim sinyal 'true' untuk refresh
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan pelanggan: $e')),
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
        title: Text(widget.customer == null
            ? 'Tambah Pelanggan Baru'
            : 'Edit Pelanggan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            // Menggunakan ListView agar bisa di-scroll
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nama Lengkap'),
                validator: (value) =>
                    value!.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Nomor Telepon'),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value!.isEmpty ? 'Nomor telepon tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _alamatController,
                decoration: InputDecoration(labelText: 'Alamat (OpsionaRl)'),
                keyboardType: TextInputType.streetAddress,
              ),
              SizedBox(height: 20),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveCustomer,
                      child:
                          Text(widget.customer == null ? 'Simpan' : 'Update'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
