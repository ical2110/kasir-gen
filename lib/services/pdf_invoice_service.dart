import 'dart:io';
import 'package:intl/intl.dart';
import 'package:kasir_gen/models/transaction.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfInvoiceService {
  Future<File> generate(Transaction transaction) async {
    final pdf = pw.Document();
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormatter = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. Header
              pw.Center(
                child: pw.Text('GenesisxClean',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 24)),
              ),
              pw.Divider(height: 20),

              // 2. Info Transaksi dan Pelanggan
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Kepada:'),
                      pw.Text(transaction.customer?.name ?? 'Pelanggan',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(transaction.customer?.phone ?? ''),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                          'No. Transaksi: ${transaction.id.length > 8 ? transaction.id.substring(0, 8) : transaction.id}...'),
                      // Gunakan tanggal selesai jika ada, jika tidak gunakan tanggal dibuat
                      pw.Text(// Perbaikan: Menggunakan tanggal yang benar
                          'Tanggal: ${dateFormatter.format(transaction.completedAt ?? transaction.createdAt ?? DateTime.now())}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 40),

              // 3. Tabel Item
              pw.Text('Detail Pesanan',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.Divider(),
              pw.TableHelper.fromTextArray(
                headers: ['Layanan', 'Kuantitas', 'Harga Satuan', 'Total'],
                data: transaction.items.map((item) {
                  return [
                    item.serviceName,
                    item.quantity.toString(),
                    currencyFormatter.format(item.price),
                    currencyFormatter.format(item.subtotal),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                },
              ),
              pw.Divider(),

              // 4. Total Keseluruhan
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('GRAND TOTAL: ',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 18)),
                  pw.Text(currencyFormatter.format(transaction.totalAmount),
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 18)),
                ],
              ),
              pw.SizedBox(height: 50),

              // 5. Footer
              pw.Center(
                child: pw.Text('Terima kasih telah menggunakan jasa kami!',
                    style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
              ),
            ],
          );
        },
      ),
    );

    return _saveDocument(name: 'invoice-${transaction.id}.pdf', pdf: pdf);
  }

  Future<File> _saveDocument({
    required String name,
    required pw.Document pdf,
  }) async {
    final bytes = await pdf.save();

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$name');

    await file.writeAsBytes(bytes);

    return file;
  }

  Future<void> openFile(File file) async {
    final url = file.path;
    await OpenFile.open(url);
  }
}
