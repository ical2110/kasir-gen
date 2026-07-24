import 'dart:io';

import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import '../models/transaction.dart';
import 'invoice_pdf_document.dart';
import 'pdf_invoice_service_stub.dart';

class _IoPdfInvoiceService implements PdfInvoiceService {
  @override
  Future<void> generateAndOpen(Transaction transaction) async {
    final bytes = await buildInvoicePdf(transaction);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/invoice-${transaction.id}.pdf');
    await file.writeAsBytes(bytes, flush: true);
    await OpenFile.open(file.path);
  }
}

PdfInvoiceService getPdfInvoiceService() => _IoPdfInvoiceService();
