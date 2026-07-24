import 'package:flutter/material.dart';
import '../models/transaction.dart';
import 'printing_service_stub.dart';

class PrintingServiceImpl implements PrintingService {
  @override
  Future<void> printReceipt(
      BuildContext context, Transaction transaction) async {
    // Web implementation: Show a snackbar as direct printing is not supported.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              'Pencetakan struk via Bluetooth tidak didukung di web. Gunakan opsi PDF.')),
    );
  }
}

PrintingService getPrintingService() => PrintingServiceImpl();
