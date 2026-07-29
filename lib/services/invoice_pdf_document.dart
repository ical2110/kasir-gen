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
            child: pw.SizedBox(
              width: 260,
              child: pw.Column(
                children: [
                  _amountRow(
                    'Subtotal',
                    currency.format(transaction.subtotalAmount),
                  ),
                  if (transaction.discountAmount > 0)
                    _amountRow(
                      transaction.discountType == DiscountType.percent
                          ? 'Diskon (${transaction.discountValue.toStringAsFixed(0)}%)'
                          : 'Diskon',
                      '- ${currency.format(transaction.discountAmount)}',
                    ),
                  pw.Divider(),
                  _amountRow(
                    'GRAND TOTAL',
                    currency.format(transaction.totalAmount),
                    bold: true,
                    fontSize: 16,
                  ),
                  if ((transaction.discountNotes ?? '').isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 6),
                      child: pw.Text(
                        'Catatan: ${transaction.discountNotes}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (transaction.status == TransactionStatus.paid) ...[
            pw.SizedBox(height: 24),
            pw.Center(
              child: pw.Text(
                'LUNAS',
                style: pw.TextStyle(
                  color: PdfColors.green700,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  return pdf.save();
}

pw.Widget _amountRow(
  String label,
  String value, {
  bool bold = false,
  double fontSize = 11,
}) {
  final style = pw.TextStyle(
    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    fontSize: fontSize,
  );
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text(value, style: style),
      ],
    ),
  );
}
