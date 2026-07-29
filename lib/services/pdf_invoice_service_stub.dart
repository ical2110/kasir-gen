import '../models/transaction.dart';

abstract class PdfInvoiceService {
  Future<void> generateAndOpen(Transaction transaction);
  Future<void> generateAndShare(Transaction transaction);
}

PdfInvoiceService getPdfInvoiceService() => _UnsupportedPdfInvoiceService();

class _UnsupportedPdfInvoiceService implements PdfInvoiceService {
  @override
  Future<void> generateAndOpen(Transaction transaction) {
    throw UnsupportedError('Pembuatan PDF tidak didukung di platform ini.');
  }

  @override
  Future<void> generateAndShare(Transaction transaction) {
    throw UnsupportedError('Berbagi PDF tidak didukung di platform ini.');
  }
}
