import 'dart:html' as html;
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

import '../models/transaction.dart';
import 'invoice_pdf_document.dart';
import 'pdf_invoice_service_stub.dart';

class _WebPdfInvoiceService implements PdfInvoiceService {
  @override
  Future<void> generateAndOpen(Transaction transaction) async {
    final bytes = await buildInvoicePdf(transaction);
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final link = html.AnchorElement(href: url)
      ..download = 'invoice-${transaction.id}.pdf'
      ..style.display = 'none';

    html.document.body?.children.add(link);
    link.click();
    link.remove();
    html.Url.revokeObjectUrl(url);
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
