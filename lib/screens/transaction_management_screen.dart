import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kasir_gen/screens/transaction_form_screen.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../services/export_service.dart'; // Import service ekspor

class TransactionManagementScreen extends StatefulWidget {
  const TransactionManagementScreen({super.key});

  @override
  State<TransactionManagementScreen> createState() =>
      _TransactionManagementScreenState();
}

class _TransactionManagementScreenState
    extends State<TransactionManagementScreen> {
  final ApiService _apiService = ApiService();
  final ExportService _exportService = ExportService(); // Inisialisasi service
  late Future<List<Transaction>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _refreshTransactions();
  }

  void _refreshTransactions() {
    setState(() {
      // Asumsi getTransactions akan melakukan join dan mengambil nama customer/service
      _transactionsFuture = _apiService.getTransactions();
    });
  }

  void _navigateAndRefresh() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TransactionFormScreen(),
      ),
    );
    if (result == true) {
      _refreshTransactions();
    }
  }

  void _deleteTransaction(String id) async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text(
              'Apakah Anda yakin ingin menghapus transaksi ini? Tindakan ini tidak dapat dibatalkan.'),
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

      await _apiService.deleteTransaction(id);
      _refreshTransactions();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus transaksi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormatter =
        DateFormat('dd MMM yyyy, HH:mm', 'id_ID'); // Formatter untuk tanggal
    List<Transaction> currentTransactions = []; // Untuk menyimpan data saat ini

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_for_offline),
            onPressed: () => _exportService.exportTransactionsToXls(
                context, currentTransactions),
            tooltip: 'Ekspor ke Excel',
          ),
        ],
      ),
      body: FutureBuilder<List<Transaction>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada transaksi.'));
          }

          currentTransactions = snapshot.data!; // Simpan data ke variabel
          return ListView.builder(
            itemCount: currentTransactions.length,
            itemBuilder: (context, index) {
              final trx = currentTransactions[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    // Anda perlu memodifikasi API untuk mengirim nama customer dan service
                    // Untuk sementara, kita tampilkan ID-nya
                    'Pelanggan: ${trx.customer?.name ?? trx.customerId}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Layanan: ${trx.service?.name ?? trx.serviceId}'),
                      Text('Status: ${statusToDisplayString(trx.status)}'),
                      Text(
                          'Total: ${currencyFormatter.format(trx.totalAmount)}'),
                      if (trx.createdAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Tgl: ${dateFormatter.format(trx.createdAt!)}',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteTransaction(trx.id),
                    tooltip: 'Hapus Transaksi',
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateAndRefresh(),
        tooltip: 'Tambah Transaksi',
        child: const Icon(Icons.add),
      ),
    );
  }
}
