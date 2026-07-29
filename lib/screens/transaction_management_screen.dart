import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kasir_gen/screens/transaction_form_screen.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../services/export_service.dart'; // Import service ekspor
import '../services/pdf_invoice_service.dart';

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
  final PdfInvoiceService _pdfService = getPdfInvoiceService();
  DateTime _selectedDate = DateTime.now();
  late Future<List<Transaction>> _transactionsFuture;
  List<Transaction> _currentTransactions =
      []; // Variabel state untuk menyimpan data

  @override
  void initState() {
    super.initState();
    _refreshTransactions();
  }

  void _refreshTransactions() {
    setState(() {
      // Memulai future untuk FutureBuilder
      final future = _apiService.getTransactions(
        year: _selectedDate.year,
        month: _selectedDate.month,
      );
      _transactionsFuture = future;
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
      // Refresh data untuk bulan yang sedang ditampilkan
      _refreshTransactions();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Transaksi berhasil dihapus.'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus transaksi: $e')),
      );
    }
  }

  void _changeMonth(int increment) {
    setState(() {
      _selectedDate =
          DateTime(_selectedDate.year, _selectedDate.month + increment, 1);
      _refreshTransactions();
    });
  }

  Future<void> _sharePaidReceipt(Transaction transaction) async {
    try {
      await _pdfService.generateAndShare(transaction);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membagikan struk: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormatter =
        DateFormat('dd MMM yyyy, HH:mm', 'id_ID'); // Formatter untuk tanggal
    final now = DateTime.now();
    final isCurrentOrFutureMonth = _selectedDate.year > now.year ||
        (_selectedDate.year == now.year && _selectedDate.month >= now.month);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_for_offline),
            // Langsung ekspor data bulan yang sedang ditampilkan
            onPressed: () => _exportService.exportTransactionsToXls(
                context, _currentTransactions, 'Laporan_Transaksi'),
            tooltip: 'Ekspor ke Excel',
          ),
        ],
      ),
      body: Column(
        children: [
          // Widget untuk Filter Bulan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                  tooltip: 'Bulan Sebelumnya',
                ),
                Text(
                  DateFormat('MMMM yyyy', 'id_ID').format(_selectedDate),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  // Tombol dinonaktifkan jika bulan yang dipilih adalah bulan ini atau masa depan
                  onPressed:
                      isCurrentOrFutureMonth ? null : () => _changeMonth(1),
                  tooltip: 'Bulan Berikutnya',
                ),
              ],
            ),
          ),
          // Daftar Transaksi
          Expanded(
            child: FutureBuilder<List<Transaction>>(
              future: _transactionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('Tidak ada transaksi pada bulan ini.'));
                }

                // Sinkronkan data saat ini dengan state untuk keperluan ekspor
                _currentTransactions = snapshot.data!;
                final transactions = snapshot.data!;

                return ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final trx = transactions[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(
                          'Pelanggan: ${trx.customer?.name ?? trx.customerId}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Layanan: ${trx.items.map((e) => e.serviceName).join(', ')}'),
                            Text(
                                'Status: ${statusToDisplayString(trx.status)}'),
                            Text(
                              'Dibuat oleh: ${trx.creatorName.isEmpty ? 'Nama belum tersedia' : trx.creatorName}',
                            ),
                            Text(
                                'Total: ${currencyFormatter.format(trx.totalAmount)}'),
                            if (trx.createdAt != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                    'Tgl: ${dateFormatter.format(trx.createdAt!)}',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12)),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (trx.status == TransactionStatus.paid)
                              IconButton(
                                icon: const Icon(Icons.share,
                                    color: Colors.green),
                                onPressed: () => _sharePaidReceipt(trx),
                                tooltip: 'Bagikan struk ke WhatsApp',
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () => _deleteTransaction(trx.id),
                              tooltip: 'Hapus Transaksi',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateAndRefresh(),
        tooltip: 'Tambah Transaksi',
        child: const Icon(Icons.add),
      ),
    );
  }
}
