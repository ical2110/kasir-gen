import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_gen/models/customer.dart';
import 'package:kasir_gen/models/service.dart';
import 'package:kasir_gen/models/service_price.dart';
import 'package:kasir_gen/models/transaction.dart';
import 'package:kasir_gen/models/transaction_item.dart';
import 'package:kasir_gen/services/session_service.dart';

void main() {
  group('pemetaan data Firestore', () {
    test('update customer tidak menulis ulang created_at', () {
      final data = Customer(id: 'c1', name: 'Ani', phone: '0812').toMap(
        includeId: false,
        includeCreatedAt: false,
      );

      expect(data, isNot(contains('created_at')));
      expect(data['full_name'], 'Ani');
    });

    test('update layanan mempertahankan ID varian harga', () {
      final price = ServicePrice(
        priceId: 'price-reguler',
        serviceId: 'service-1',
        price: 12000,
        notes: 'Reguler',
      );
      final data = Service(
        id: 'service-1',
        name: 'Cuci',
        prices: [price],
      ).toMap(includeId: false, includeCreatedAt: false);

      expect(data, isNot(contains('created_at')));
      expect((data['prices'] as List).single['price_id'], 'price-reguler');
    });

    test('update transaksi tidak menulis ulang created_at', () {
      final transaction = Transaction(
        id: 'trx-1',
        customerId: 'c1',
        totalAmount: 15000,
        status: TransactionStatus.in_progress,
        items: [
          TransactionItem(
            serviceId: 's1',
            serviceName: 'Cuci',
            priceId: 'p1',
            price: 15000,
            quantity: 1,
            subtotal: 15000,
          ),
        ],
      );

      expect(
        transaction.toMap(includeId: false, includeCreatedAt: false),
        isNot(contains('created_at')),
      );
    });

    test('transaksi menyimpan snapshot diskon dan total akhir', () {
      final transaction = Transaction(
        id: 'trx-diskon',
        customerId: 'c1',
        subtotalAmount: 100000,
        discountType: DiscountType.percent,
        discountValue: 10,
        discountAmount: 10000,
        discountNotes: 'Pelanggan langganan',
        totalAmount: 90000,
        status: TransactionStatus.paid,
        items: const [],
      );

      final data = transaction.toMap(includeId: false, includeCreatedAt: false);

      expect(data['subtotal_amount'], 100000);
      expect(data['discount_type'], 'percent');
      expect(data['discount_value'], 10);
      expect(data['discount_amount'], 10000);
      expect(data['total_amount'], 90000);
    });

    test('perhitungan diskon dibatasi agar total tidak negatif', () {
      expect(
        calculateDiscountAmount(100000, DiscountType.percent, 10),
        10000,
      );
      expect(
        calculateDiscountAmount(100000, DiscountType.fixed, 120000),
        100000,
      );
    });

    test('tanggal transaksi lama memakai waktu selesai sebagai fallback', () {
      final completedAt = DateTime(2026, 7, 29, 12);
      final transaction = Transaction(
        id: 'trx-lama',
        customerId: 'c1',
        totalAmount: 50000,
        status: TransactionStatus.paid,
        completedAt: completedAt,
        items: const [],
      );

      expect(transaction.effectiveDate, completedAt);
    });
  });

  group('batas session', () {
    final now = DateTime(2026, 7, 29, 12);

    test('session berakhir setelah tidak aktif lebih dari 12 jam', () {
      expect(
        SessionService.shouldExpire(
          now: now,
          lastActivity: now.subtract(const Duration(hours: 13)),
          signedInAt: now.subtract(const Duration(days: 1)),
        ),
        isTrue,
      );
    });

    test('session berakhir setelah berumur lebih dari 7 hari', () {
      expect(
        SessionService.shouldExpire(
          now: now,
          lastActivity: now.subtract(const Duration(minutes: 10)),
          signedInAt: now.subtract(const Duration(days: 8)),
        ),
        isTrue,
      );
    });

    test('session aktif tetap dipertahankan', () {
      expect(
        SessionService.shouldExpire(
          now: now,
          lastActivity: now.subtract(const Duration(hours: 2)),
          signedInAt: now.subtract(const Duration(days: 2)),
        ),
        isFalse,
      );
    });
  });
}
