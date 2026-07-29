import 'dart:io';

import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/transaction.dart';
import 'invoice_pdf_document.dart';
import 'pdf_invoice_service_stub.dart';

class _IoPdfInvoiceService implements PdfInvoiceService {
  Future<File> _generateFile(Transaction transaction) async {
    final bytes = await buildInvoicePdf(transaction);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/invoice-${transaction.id}.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  @override
  Future<void> generateAndOpen(Transaction transaction) async {
    final file = await _generateFile(transaction);
    await OpenFile.open(file.path);
  }

  @override
  Future<void> generateAndShare(Transaction transaction) async {
    final file = await _generateFile(transaction);
    await Share.shareXFiles(
      [
        XFile(file.path, mimeType: 'application/pdf'),
      ],
      subject: 'Struk pembayaran',
      text: 'Struk pembayaran ${transaction.customer?.name ?? ''}'.trim(),
      fileNameOverrides: ['struk-${transaction.id}.pdf'],
    );
  }
}

PdfInvoiceService getPdfInvoiceService() => _IoPdfInvoiceService();
