import 'dart:js_interop';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';
import 'package:web/web.dart' as web;

import '../models/transaction.dart';
import 'invoice_pdf_document.dart';
import 'pdf_invoice_service_stub.dart';

class _WebPdfInvoiceService implements PdfInvoiceService {
  @override
  Future<void> generateAndOpen(Transaction transaction) async {
    final bytes = await buildInvoicePdf(transaction);
    final data = Uint8List.fromList(bytes).toJS;
    final blob = web.Blob(
      <web.BlobPart>[data].toJS,
      web.BlobPropertyBag(type: 'application/pdf'),
    );
    final url = web.URL.createObjectURL(blob);
    final link = web.HTMLAnchorElement()
      ..href = url
      ..download = 'invoice-${transaction.id}.pdf'
      ..style.display = 'none';

    web.document.body?.appendChild(link);
    link.click();
    link.remove();
    web.URL.revokeObjectURL(url);
  }

  @override
  Future<void> generateAndShare(Transaction transaction) async {
    final bytes = await buildInvoicePdf(transaction);
    await Share.shareXFiles(
      [
        XFile.fromData(
          Uint8List.fromList(bytes),
          mimeType: 'application/pdf',
        ),
      ],
      subject: 'Struk pembayaran',
      text: 'Struk pembayaran ${transaction.customer?.name ?? ''}'.trim(),
      fileNameOverrides: ['struk-${transaction.id}.pdf'],
    );
  }
}

PdfInvoiceService getPdfInvoiceService() => _WebPdfInvoiceService();
