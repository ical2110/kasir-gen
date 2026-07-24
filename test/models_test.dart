import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_gen/models/customer.dart';
import 'package:kasir_gen/models/service.dart';
import 'package:kasir_gen/models/service_price.dart';
import 'package:kasir_gen/models/transaction.dart';
import 'package:kasir_gen/models/transaction_item.dart';

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
  });
}
