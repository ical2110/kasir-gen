import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kasir_gen/models/transaction.dart';
import 'package:kasir_gen/services/api_service.dart';
import 'package:kasir_gen/services/printing_service.dart';
import 'package:kasir_gen/services/pdf_invoice_service.dart';
import 'package:kasir_gen/screens/transaction_form_screen.dart';
import 'package:kasir_gen/screens/account_management_screen.dart';
import 'package:kasir_gen/services/role_service.dart';
import '../../widgets/app_drawer.dart'; // Import drawer yang sudah kita buat

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final PrintingService _printingService = getPrintingService();
  final PdfInvoiceService _pdfService = getPdfInvoiceService();
  late Future<List<Transaction>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _refreshTransactions();
  }

  void _refreshTransactions() {
    setState(() {
      // Hanya ambil transaksi yang statusnya 'in_progress' atau 'completed'
      _transactionsFuture = _apiService.getTransactions(statuses: [
        TransactionStatus.in_progress,
        TransactionStatus.completed,
      ]).catchError((e) {
        // Tangani error di sini juga, jika terjadi saat memuat data
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memuat data: $e')),
          );
        }
        // Kembalikan list kosong atau throw error agar FutureBuilder bisa menanganinya
        return <Transaction>[];
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
      // Tidak perlu update state manual, cukup refresh data dari server
      // setelah operasi berhasil.
      final updatedTransaction = transaction.copyWith(
        status: TransactionStatus.completed,
        completedAt: DateTime.now(),
      );

      await _apiService.updateTransactionStatus(
        updatedTransaction.id,
        updatedTransaction.status,
        completedAt: updatedTransaction.completedAt,
      );

      // Panggil refresh untuk memuat ulang data dari server
      _refreshTransactions();

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
            await _pdfService.generateAndOpen(updatedTransaction);
            if (!mounted) return;
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              // Aman karena di dalam blok sinkron setelah dialog
              SnackBar(content: Text('Gagal membuat PDF: $e')),
            );
          }
        } else if (action == 'print') {
          if (!mounted) return;
          await _printingService.printReceipt(context, updatedTransaction);
        }
      }
    } catch (e) {
      // Jika gagal, muat ulang data dari server untuk mengembalikan state
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          // Aman karena sudah di dalam mounted check
          SnackBar(content: Text('Gagal memperbarui status: $e')),
        );
        _refreshTransactions();
      }
    }
  }

  Future<void> _payTransaction(Transaction transaction) async {
    final payment = await showDialog<_PaymentDiscountResult>(
      context: context,
      builder: (context) => _PaymentDiscountDialog(transaction: transaction),
    );

    if (payment == null) return;

    try {
      // Optimistic UI Update: Hapus item dari daftar lokal secara langsung
      // Tidak perlu update state manual, cukup refresh data dari server.

      // Kirim pembaruan ke API di latar belakang
      final updatedTransaction = transaction.copyWith(
        status: TransactionStatus.paid,
        completedAt: transaction.completedAt ?? DateTime.now(),
        subtotalAmount: payment.subtotalAmount,
        discountType: payment.discountType,
        discountValue: payment.discountValue,
        discountAmount: payment.discountAmount,
        discountNotes: payment.discountNotes,
        totalAmount: payment.totalAmount,
      );
      await _apiService.updateTransactionStatus(
        updatedTransaction.id,
        updatedTransaction.status,
        completedAt: updatedTransaction.completedAt,
        subtotalAmount: updatedTransaction.subtotalAmount,
        discountType: updatedTransaction.discountType,
        discountValue: updatedTransaction.discountValue,
        discountAmount: updatedTransaction.discountAmount,
        discountNotes: updatedTransaction.discountNotes,
        totalAmount: updatedTransaction.totalAmount,
      );

      // Panggil refresh untuk memuat ulang data dari server
      _refreshTransactions();

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
          StreamBuilder<AppUser?>(
            stream: RoleService.watchCurrentUser(),
            builder: (context, snapshot) {
              if (snapshot.data?.isAdmin != true) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.admin_panel_settings),
                tooltip: 'Verifikasi Akun',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountManagementScreen(),
                    ),
                  );
                },
              );
            },
          ),
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

          // Langsung gunakan data dari snapshot.
          final activeTransactions = snapshot.data ?? [];

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
                      '${trx.items.map((e) => e.serviceName).join(', ')}\n${currencyFormatter.format(trx.totalAmount)}'),
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

class _PaymentDiscountResult {
  const _PaymentDiscountResult({
    required this.subtotalAmount,
    required this.discountType,
    required this.discountValue,
    required this.discountAmount,
    required this.discountNotes,
  });

  final double subtotalAmount;
  final DiscountType discountType;
  final double discountValue;
  final double discountAmount;
  final String discountNotes;

  double get totalAmount => subtotalAmount - discountAmount;
}

class _PaymentDiscountDialog extends StatefulWidget {
  const _PaymentDiscountDialog({required this.transaction});

  final Transaction transaction;

  @override
  State<_PaymentDiscountDialog> createState() => _PaymentDiscountDialogState();
}

class _PaymentDiscountDialogState extends State<_PaymentDiscountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valueController;
  late final TextEditingController _notesController;
  late DiscountType _discountType;

  double get _subtotal {
    if (widget.transaction.subtotalAmount > 0) {
      return widget.transaction.subtotalAmount;
    }
    return widget.transaction.items.fold(
      0,
      (total, item) => total + item.subtotal,
    );
  }

  double get _discountValue => double.tryParse(_valueController.text) ?? 0;

  double get _discountAmount => calculateDiscountAmount(
        _subtotal,
        _discountType,
        _discountValue,
      );

  @override
  void initState() {
    super.initState();
    _discountType = widget.transaction.discountType;
    _valueController = TextEditingController(
      text: widget.transaction.discountValue > 0
          ? widget.transaction.discountValue.toStringAsFixed(0)
          : '',
    )..addListener(_refresh);
    _notesController =
        TextEditingController(text: widget.transaction.discountNotes);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _valueController
      ..removeListener(_refresh)
      ..dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _PaymentDiscountResult(
        subtotalAmount: _subtotal,
        discountType: _discountType,
        discountValue: _discountType == DiscountType.none ? 0 : _discountValue,
        discountAmount: _discountAmount,
        discountNotes: _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return AlertDialog(
      title: const Text('Konfirmasi Pembayaran'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<DiscountType>(
                  initialValue: _discountType,
                  decoration: const InputDecoration(labelText: 'Jenis diskon'),
                  items: DiscountType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(discountTypeToDisplayString(type)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _discountType = value ?? DiscountType.none;
                      if (_discountType == DiscountType.none) {
                        _valueController.clear();
                      }
                    });
                  },
                ),
                if (_discountType != DiscountType.none) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _valueController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: _discountType == DiscountType.percent
                          ? 'Diskon (%)'
                          : 'Diskon (Rp)',
                    ),
                    validator: (value) {
                      final number = double.tryParse(value ?? '');
                      if (number == null || number <= 0) {
                        return 'Nilai diskon harus lebih dari 0';
                      }
                      if (_discountType == DiscountType.percent &&
                          number > 100) {
                        return 'Persentase maksimal 100%';
                      }
                      if (_discountType == DiscountType.fixed &&
                          number > _subtotal) {
                        return 'Diskon tidak boleh melebihi subtotal';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Catatan diskon (opsional)',
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                _PaymentAmountRow(
                  label: 'Subtotal',
                  value: currency.format(_subtotal),
                ),
                if (_discountAmount > 0)
                  _PaymentAmountRow(
                    label: 'Potongan',
                    value: '- ${currency.format(_discountAmount)}',
                    valueColor: Colors.green,
                  ),
                const Divider(),
                _PaymentAmountRow(
                  label: 'Total pembayaran',
                  value: currency.format(_subtotal - _discountAmount),
                  bold: true,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: const Text('Konfirmasi Bayar'),
        ),
      ],
    );
  }
}

class _PaymentAmountRow extends StatelessWidget {
  const _PaymentAmountRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: valueColor,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          const SizedBox(width: 24),
          Text(value, style: style),
        ],
      ),
    );
  }
}
