import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kasir_gen/models/transaction.dart';
import 'package:kasir_gen/services/api_service.dart';
import 'package:kasir_gen/services/printing_service.dart';
import 'package:kasir_gen/services/pdf_invoice_service.dart';
import 'package:kasir_gen/screens/transaction_form_screen.dart';
import '../../widgets/app_drawer.dart'; // Import drawer yang sudah kita buat

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final PrintingService _printingService = PrintingService();
  final PdfInvoiceService _pdfService = PdfInvoiceService();
  late Future<List<Transaction>> _transactionsFuture;
  List<Transaction> _transactions = []; // State untuk menyimpan data transaksi

  @override
  void initState() {
    super.initState();
    _refreshTransactions();
  }

  void _refreshTransactions() {
    setState(() {
      _transactionsFuture = _apiService.getTransactions().then((transactions) {
        // Simpan hasil ke state lokal setelah berhasil dimuat
        _transactions = transactions;
        return transactions;
      });
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

  Future<void> _completeTransaction(Transaction transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selesaikan Pesanan'),
        content: Text(
            'Apakah Anda yakin ingin menyelesaikan pesanan untuk pelanggan "${transaction.customer?.name ?? transaction.customerId}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Selesaikan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Optimistic UI Update yang lebih ringkas dan aman
      final transactionIndex =
          _transactions.indexWhere((t) => t.id == transaction.id);
      setState(() {
        if (transactionIndex != -1) {
          _transactions[transactionIndex] =
              transaction.copyWith(status: TransactionStatus.completed);
        }
      });

      // Kirim pembaruan ke API di latar belakang
      final updatedTransaction = transaction.copyWith(
        status:
            TransactionStatus.completed, // Perbaikan: Menggunakan completedAt
        completedAt: DateTime.now(),
      );
      await _apiService.updateTransaction(updatedTransaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan telah diselesaikan!')),
        );

        // Tampilkan dialog untuk cetak struk
        final action = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Tindakan Lanjutan'),
            content: const Text('Pilih tindakan untuk pesanan ini:'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop('pdf'),
                child: const Text('Buat PDF'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop('print'),
                child: const Text('Cetak Struk'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(), // Batal
                child: const Text('Tutup'),
              ),
            ],
          ),
        );

        if (action == 'pdf') {
          try {
            final file = await _pdfService.generate(updatedTransaction);
            await _pdfService.openFile(file);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal membuat PDF: $e')),
            );
          }
        } else if (action == 'print') {
          await _printingService.printReceipt(context, updatedTransaction);
        }
      }
    } catch (e) {
      // Jika gagal, muat ulang data dari server untuk mengembalikan state
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui status: $e')),
        );
        _refreshTransactions();
      }
    }
  }

  Future<void> _payTransaction(Transaction transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Pembayaran'),
        content: const Text('Apakah Anda yakin pesanan ini sudah dibayar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sudah Dibayar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Optimistic UI Update: Hapus item dari daftar lokal secara langsung
      setState(() {
        _transactions.removeWhere((t) => t.id == transaction.id);
      });

      // Kirim pembaruan ke API di latar belakang
      final updatedTransaction =
          transaction.copyWith(status: TransactionStatus.paid);
      await _apiService.updateTransaction(updatedTransaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan telah dibayar!')),
        );
      }
    } catch (e) {
      // Jika gagal, muat ulang data dari server untuk mengembalikan state
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui status: $e')),
        );
        _refreshTransactions();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Pesanan Aktif'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTransactions,
            tooltip: 'Segarkan Data',
          ),
        ],
      ),
      drawer: const AppDrawer(), // Gunakan widget AppDrawer yang sudah dipisah
      body: FutureBuilder<List<Transaction>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada transaksi.'));
          }

          // Gunakan state _transactions yang sudah aman
          // Filter transaksi yang belum dibayar (in_progress atau completed)
          final activeTransactions = _transactions
              .where((trx) => trx.status != TransactionStatus.paid)
              .toList();

          if (activeTransactions.isEmpty &&
              snapshot.connectionState == ConnectionState.done) {
            return const Center(
                child: Text('Tidak ada pesanan yang sedang berjalan.'));
          }

          return ListView.builder(
            itemCount: activeTransactions.length,
            itemBuilder: (context, index) {
              final trx = activeTransactions[index];
              final bool isInProgress =
                  trx.status == TransactionStatus.in_progress;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(trx.customer?.name ?? 'ID: ${trx.customerId}'),
                  subtitle: Text(
                      '${trx.service?.name ?? 'ID: ${trx.serviceId}'}\n${currencyFormatter.format(trx.totalAmount)}'),
                  trailing: isInProgress
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.touch_app_outlined),
                            Text('Selesaikan'),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payment, color: Colors.green.shade700),
                            Text('Bayar',
                                style: TextStyle(color: Colors.green.shade700)),
                          ],
                        ),
                  isThreeLine: true,
                  onTap: () => isInProgress
                      ? _completeTransaction(trx)
                      : _payTransaction(trx),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateAndRefresh,
        tooltip: 'Tambah Transaksi',
        icon: const Icon(Icons.add),
        label: const Text('Tambah Transaksi'),
      ),
    );
  }
}
