import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';

import '../models/transaction.dart';
import 'invoice_pdf_document.dart';
import 'pdf_invoice_service_stub.dart';

class _WebPdfInvoiceService implements PdfInvoiceService {
  @override
  Future<void> generateAndOpen(Transaction transaction) async {
    final bytes = await buildInvoicePdf(transaction);
    await FileSaver.instance.saveAs(
      name: 'invoice-${transaction.id}',
      bytes: Uint8List.fromList(bytes),
      ext: 'pdf',
      mimeType: MimeType.pdf,
    );
  }
}

PdfInvoiceService getPdfInvoiceService() => _WebPdfInvoiceService();
