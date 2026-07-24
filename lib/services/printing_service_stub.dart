import 'package:flutter/material.dart';
import 'package:kasir_gen/models/transaction.dart';

/// Abstract class definition for PrintingService.
/// This will be implemented by platform-specific files.
abstract class PrintingService {
  Future<void> printReceipt(BuildContext context, Transaction transaction);
}

PrintingService getPrintingService() => _UnsupportedPrintingService();

class _UnsupportedPrintingService implements PrintingService {
  @override
  Future<void> printReceipt(
    BuildContext context,
    Transaction transaction,
  ) async {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Pencetakan tidak didukung di platform ini.')),
    );
  }
}
