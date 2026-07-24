import 'pdf_invoice_service_stub.dart';
import 'pdf_invoice_service_stub.dart'
    if (dart.library.io) 'pdf_invoice_service_io.dart'
    if (dart.library.html) 'pdf_invoice_service_web.dart' as implementation;

export 'pdf_invoice_service_stub.dart';

PdfInvoiceService getPdfInvoiceService() =>
    implementation.getPdfInvoiceService();
