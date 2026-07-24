import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/transaction.dart';

Future<List<int>> buildInvoicePdf(Transaction transaction) async {
  final pdf = pw.Document();
  final currency =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final date = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Text(
              'GenesisxClean',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24),
            ),
          ),
          pw.Divider(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Kepada:'),
                  pw.Text(
                    transaction.customer?.name ?? 'Pelanggan',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(transaction.customer?.phone ?? ''),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('No. Transaksi: ${transaction.id}'),
                  pw.Text(
                    'Tanggal: ${date.format(transaction.completedAt ?? transaction.createdAt ?? DateTime.now())}',
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 32),
          pw.TableHelper.fromTextArray(
            headers: ['Layanan', 'Kuantitas', 'Harga Satuan', 'Total'],
            data: transaction.items
                .map((item) => [
                      item.serviceName,
                      item.quantity.toString(),
                      currency.format(item.price),
                      currency.format(item.subtotal),
                    ])
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          ),
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'GRAND TOTAL: ${currency.format(transaction.totalAmount)}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
    ),
  );

  return pdf.save();
}
