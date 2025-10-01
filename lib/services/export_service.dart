import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kasir_gen/models/transaction.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ExportService {
  Future<void> exportTransactionsToXls(
      BuildContext context, List<Transaction> transactions) async {
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diekspor.')),
      );
      return;
    }

    // 1. Minta Izin (jika diperlukan, terutama untuk Android versi lama)
    // Untuk iOS dan Android modern, izin tidak diperlukan untuk menulis ke direktori dokumen aplikasi.
    // Namun, kita tetap bisa memintanya untuk kompatibilitas.
    if (Platform.isAndroid) {
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Izin penyimpanan ditolak. Tidak dapat ekspor.')),
        );
        return;
      }
    }

    // 2. Buat Workbook dan Sheet Excel
    final excel = Excel.createExcel();
    final Sheet sheet = excel[excel.getDefaultSheet()!];

    // 3. Buat Header Tabel
    final headers = [
      'ID Transaksi',
      'Tanggal',
      'Pelanggan',
      'Layanan',
      'Kuantitas',
      'Total Harga',
      'Status',
      'Catatan',
    ];
    sheet.appendRow(headers.map((header) => TextCellValue(header)).toList());

    // Formatter
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final dateFormatter = DateFormat('dd-MM-yyyy HH:mm', 'id_ID');

    // 4. Isi Data Transaksi
    for (var trx in transactions) {
      final row = [
        TextCellValue(trx.id),
        TextCellValue(
            trx.createdAt != null ? dateFormatter.format(trx.createdAt!) : '-'),
        TextCellValue(trx.customer?.name ?? trx.customerId),
        TextCellValue(trx.service?.name ?? trx.serviceId),
        IntCellValue(trx.quantity),
        TextCellValue(currencyFormatter.format(trx.totalAmount)),
        TextCellValue(statusToDisplayString(trx.status)),
        TextCellValue(trx.notes ?? '-'),
      ];
      sheet.appendRow(row);
    }

    // 5. Simpan File
    try {
      // Menggunakan getApplicationDocumentsDirectory agar kompatibel dengan iOS & Android
      final Directory? dir = await getApplicationDocumentsDirectory();

      if (dir == null) {
        throw Exception("Tidak dapat menemukan direktori penyimpanan.");
      }

      final String fileName =
          'Laporan_Transaksi_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final String filePath = '${dir.path}/$fileName';

      final fileBytes = excel.save();
      if (fileBytes != null) {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ekspor berhasil! Tersimpan di $filePath')),
        );
        // Buka file setelah berhasil disimpan
        await OpenFile.open(filePath);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan file: $e')),
      );
    }
  }
}
