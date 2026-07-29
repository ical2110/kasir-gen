import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import 'printing_service_stub.dart';

class PrintingServiceImpl implements PrintingService {
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  @override
  Future<void> printReceipt(
      BuildContext context, Transaction transaction) async {
    try {
      // 1. Cek apakah Bluetooth tersedia dan aktif
      bool? isAvailable = await _bluetooth.isAvailable;
      if (isAvailable != true) {
        throw 'Bluetooth tidak tersedia.';
      }

      bool? isOn = await _bluetooth.isOn;
      if (isOn != true) {
        throw 'Mohon aktifkan Bluetooth Anda.';
      }

      // 2. Dapatkan daftar perangkat yang sudah di-pairing
      List<BluetoothDevice> devices = await _bluetooth.getBondedDevices();
      if (devices.isEmpty) {
        throw 'Tidak ada printer Bluetooth yang ter-pairing. Silakan pairing printer Anda melalui pengaturan Bluetooth perangkat.';
      }

      // 3. Tampilkan dialog untuk memilih printer
      BluetoothDevice? selectedDevice = await showDialog<BluetoothDevice>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Pilih Printer'),
          children: devices
              .map((device) => SimpleDialogOption(
                    onPressed: () {
                      Navigator.pop(context, device);
                    },
                    child: Text(device.name ?? 'Unknown Device'),
                  ))
              .toList(),
        ),
      );

      if (selectedDevice == null) {
        // Pengguna membatalkan dialog
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pemilihan printer dibatalkan.')));
        }
        return;
      }

      // 4. Hubungkan ke perangkat
      await _bluetooth.connect(selectedDevice);

      // 5. Siapkan dan cetak data
      _printFormattedText(transaction);

      // 6. Putuskan koneksi setelah selesai
      await _bluetooth.disconnect();
    } catch (e) {
      // Tampilkan error kepada pengguna
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _printFormattedText(Transaction transaction) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormatter = DateFormat('dd-MM-yyyy HH:mm', 'id_ID');

    _bluetooth.printCustom("STRUK PEMBAYARAN", 2, 1); // Ukuran 2, rata tengah
    _bluetooth.printCustom("Laundry Keren", 1, 1);
    _bluetooth.printNewLine();
    _bluetooth.printLeftRight("No. Transaksi:", transaction.id, 1);
    _bluetooth.printLeftRight(
        "Tanggal:",
        transaction.createdAt != null
            ? dateFormatter.format(transaction.createdAt!)
            : '-',
        1);
    _bluetooth.printLeftRight(
        "Pelanggan:", transaction.customer?.name ?? '-', 1);
    _bluetooth.printCustom("--------------------------------", 1, 1);

    for (var item in transaction.items) {
      _bluetooth.printLeftRight("${item.serviceName} (x${item.quantity})",
          currencyFormatter.format(item.subtotal), 1);
    }
    if ((transaction.notes ?? '').trim().isNotEmpty) {
      _bluetooth.printCustom("Catatan: ${transaction.notes!.trim()}", 1, 0);
    }
    _bluetooth.printCustom("--------------------------------", 1, 1);
    _bluetooth.printLeftRight(
        "Subtotal:", currencyFormatter.format(transaction.subtotalAmount), 1);
    if (transaction.discountAmount > 0) {
      final discountLabel = transaction.discountType == DiscountType.percent
          ? "Diskon ${transaction.discountValue.toStringAsFixed(0)}%:"
          : "Diskon:";
      _bluetooth.printLeftRight(discountLabel,
          "-${currencyFormatter.format(transaction.discountAmount)}", 1);
      if ((transaction.discountNotes ?? '').trim().isNotEmpty) {
        _bluetooth.printCustom(
            "Catatan diskon: ${transaction.discountNotes!.trim()}", 1, 0);
      }
    }
    _bluetooth.printLeftRight(
        "TOTAL:", currencyFormatter.format(transaction.totalAmount), 2);
    _bluetooth.printNewLine();
    _bluetooth.printCustom("Terima kasih!", 1, 1);
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
  }
}

PrintingService getPrintingService() => PrintingServiceImpl();
