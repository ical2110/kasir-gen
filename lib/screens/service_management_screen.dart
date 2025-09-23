import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Tambahkan package intl: ^0.18.1 di pubspec.yaml
import '../models/service.dart';
import '../services/api_service.dart';
import 'service_form_screen.dart';

class ServiceManagementScreen extends StatefulWidget {
  @override
  _ServiceManagementScreenState createState() =>
      _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  final ApiService apiService = ApiService();
  late Future<List<Service>> _servicesFuture;

  @override
  void initState() {
    super.initState();
    _refreshServices();
  }

  void _refreshServices() {
    setState(() {
      _servicesFuture = apiService.getServices();
    });
  }

  void _navigateAndRefresh({Service? service}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ServiceFormScreen(service: service)),
    );
    if (result == true) {
      _refreshServices();
    }
  }

  void _deleteService(String id) async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text(
              'Menghapus layanan ini juga akan menghapus semua varian harganya. Yakin?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      await apiService.deleteService(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Layanan berhasil dihapus')),
      );
      _refreshServices();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus layanan: $e')),
      );
      _refreshServices();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Formatter untuk mata uang Rupiah
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text('Manajemen Layanan'),
      ),
      body: FutureBuilder<List<Service>>(
        future: _servicesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${snapshot.error}',
                        textAlign: TextAlign.center),
                    SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: _refreshServices, child: Text('Coba Lagi')),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Belum ada layanan yang ditambahkan.'));
          } else {
            final services = snapshot.data!;
            return ListView.builder(
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(service.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  if (service.description != null &&
                                      service.description!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(service.description!),
                                    ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                    // Tombol Edit
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () =>
                                        _navigateAndRefresh(service: service)),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _deleteService(service.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        if (service.prices.isEmpty)
                          const Text('Belum ada harga untuk layanan ini.',
                              style: TextStyle(fontStyle: FontStyle.italic)),
                        ...service.prices.map((price) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(price.notes ?? 'Harga',
                                style: TextStyle(color: Colors.grey[700])),
                            trailing: Text(
                              currencyFormatter.format(price.price),
                              style: const TextStyle(
                                fontSize: 16, // Ukuran font lebih besar
                                fontWeight:
                                    FontWeight.w500, // Sedikit lebih tebal
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateAndRefresh,
        child: Icon(Icons.add),
        tooltip: 'Tambah Layanan',
      ),
    );
  }
}
