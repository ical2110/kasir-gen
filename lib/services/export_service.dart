import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kasir_gen/models/transaction.dart';
import 'package:open_file/open_file.dart';
import 'package:file_saver/file_saver.dart';

class ExportService {
  Future<void> exportTransactionsToXls(
    BuildContext context,
    List<Transaction> transactions, [
    String baseFileName = 'Laporan_Transaksi',
  ]) async {
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diekspor.')),
      );
      return;
    }

    // 1. Izin Penyimpanan
    // Pada Android modern (11+), izin tidak diperlukan untuk menulis ke direktori publik seperti Downloads.
    // Permintaan izin `Permission.storage` sudah tidak efektif dan dapat menyebabkan penolakan.

    // 2. Buat Workbook dan Sheet Excel
    final excel = Excel.createExcel();
    final Sheet sheet = excel[excel.getDefaultSheet()!];

    // 3. Buat Header Tabel
    final headers = [
      /*  'ID Transaksi', */
      'Tanggal',
      'Pelanggan',
      'Layanan',
      'Kuantitas',
      'Subtotal',
      'Drop Point',
      'Status',
      /*  'Catatan', */
    ];
    sheet.appendRow(headers.map((header) => TextCellValue(header)).toList());

    // Formatter
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final dateFormatter = DateFormat('dd-MM-yyyy HH:mm', 'id_ID');

    // 4. Isi Data Transaksi
    // Buat satu baris untuk setiap item dalam setiap transaksi
    for (var trx in transactions) {
      for (var item in trx.items) {
        // Logika ini sudah benar untuk struktur data BARU
        final row = [
          /*   TextCellValue(trx.id), */
          TextCellValue(trx.createdAt != null
              ? dateFormatter.format(trx.createdAt!)
              : '-'),
          TextCellValue(trx.customer?.name ?? trx.customerId),
          TextCellValue(item.serviceName),
          IntCellValue(item.quantity),
          TextCellValue(currencyFormatter.format(item.subtotal)),
          TextCellValue(trx.transactionSource ?? '-'),
          TextCellValue(statusToDisplayString(trx.status)),
          /*    TextCellValue(trx.notes ?? '-'), */
        ];
        sheet.appendRow(row);
      }

      // Tambahan: Logika untuk menangani struktur data LAMA
      // Jika 'items' kosong, kita coba cari data di field lama (jika ada).
      // Anda mungkin perlu menyesuaikan nama field ('service_name', 'quantity')
      // sesuai dengan struktur data lama Anda di Firestore.
      if (trx.items.isEmpty) {
        final row = [
          /*    TextCellValue(trx.id), */
          TextCellValue(trx.createdAt != null
              ? dateFormatter.format(trx.createdAt!)
              : '-'),
          TextCellValue(trx.customer?.name ?? trx.customerId), // Nama Pelanggan
          TextCellValue('Layanan (Data Lama)'), // Layanan tidak spesifik
          TextCellValue('N/A'), // Kuantitas tidak ada di struktur baru
          TextCellValue(
              currencyFormatter.format(trx.totalAmount)), // Gunakan totalAmount
          TextCellValue(trx.transactionSource ?? '-'),
          TextCellValue(statusToDisplayString(trx.status)),
          /*  TextCellValue(trx.notes ?? '-'), */
        ];
        sheet.appendRow(row);
      }
    }

    // 5. Simpan File
    try {
      final String fileName =
          '${baseFileName}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

      // Dapatkan byte dari file Excel
      final List<int>? fileBytes = excel.save();

      if (fileBytes != null) {
        // Gunakan file_saver untuk menyimpan file.
        // Menggunakan saveAs untuk membuka dialog simpan dari sistem operasi.
        // Ini lebih andal di Android modern dan memberi pengguna kontrol.
        String? path = await FileSaver.instance.saveAs(
          name: fileName,
          bytes: Uint8List.fromList(fileBytes),
          ext: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );

        // Jika path tidak null, berarti pengguna berhasil menyimpan file.
        if (path != null) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Laporan berhasil diekspor dan disimpan.')),
          );
        } else {
          // Jika path null, berarti pengguna membatalkan proses penyimpanan.
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Proses ekspor dibatalkan.')),
          );
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan file: $e')),
      );
    }
  }
}
