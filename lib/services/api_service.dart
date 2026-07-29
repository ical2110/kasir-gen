import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kasir_gen/models/customer.dart';
import 'package:kasir_gen/models/service.dart';
import 'package:kasir_gen/models/transaction.dart';

class ApiService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _ownerId {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Anda harus masuk sebelum mengakses data.');
    }
    return uid;
  }

  //============================================================================
  // CUSTOMER API
  //============================================================================

  Future<List<Customer>> getCustomers() async {
    try {
      Query<Map<String, dynamic>> query = _db.collection('customers');
      final snapshot = await query.get();
      final customers = snapshot.docs.map((doc) {
        final data = doc.data();
        data['customer_id'] = doc.id; // Tambahkan ID dokumen ke data
        return Customer.fromMap(data);
      }).toList();
      customers
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return customers;
    } catch (e) {
      throw Exception('Gagal mengambil data pelanggan: $e');
    }
  }

  Future<Customer> addCustomer(Customer customer) async {
    try {
      // Firestore akan generate ID secara otomatis
      final data = customer.toMap(includeId: false)..['owner_id'] = _ownerId;
      final docRef = await _db.collection('customers').add(data);
      // Mengembalikan customer dengan ID yang sudah dibuat menggunakan copyWith
      return customer.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Gagal menambah pelanggan: $e');
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    try {
      await _db.collection('customers').doc(customer.id).update(customer.toMap(
            includeId: false,
            includeCreatedAt: false,
          )..['owner_id'] = _ownerId);
    } catch (e) {
      throw Exception('Gagal memperbarui pelanggan: $e');
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _db.collection('customers').doc(id).delete();
    } catch (e) {
      throw Exception('Gagal menghapus pelanggan: $e');
    }
  }

  //============================================================================
  // SERVICE API
  //============================================================================

  Future<List<Service>> getServices() async {
    try {
      final snapshot = await _db.collection('services').get();
      final services = snapshot.docs.map((doc) {
        final data = doc.data();
        data['service_id'] = doc.id;
        return Service.fromMap(data);
      }).toList();
      services
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return services;
    } catch (e) {
      throw Exception('Gagal mengambil data layanan: $e');
    }
  }

  Future<Service> addService(Service service) async {
    try {
      final data = service.toMap(includeId: false)..['owner_id'] = _ownerId;
      final docRef = await _db.collection('services').add(data);
      // Membuat objek baru dengan ID yang dihasilkan.
      // Karena model Service tidak memiliki copyWith, kita buat manual.
      return Service(
          id: docRef.id,
          name: service.name,
          description: service.description,
          prices: service.prices,
          createdAt: DateTime.now(), // Asumsikan waktu dibuat adalah sekarang
          updatedAt: DateTime.now());
    } catch (e) {
      throw Exception('Gagal menambah layanan: $e');
    }
  }

  Future<void> updateService(Service service) async {
    try {
      await _db.collection('services').doc(service.id).update(service.toMap(
            includeId: false,
            includeCreatedAt: false,
          )..['owner_id'] = _ownerId);
    } catch (e) {
      throw Exception('Gagal memperbarui layanan: $e');
    }
  }

  Future<void> deleteService(String id) async {
    try {
      // Menghapus dokumen service berdasarkan ID-nya.
      // Firestore juga akan menghapus sub-koleksi (jika ada) jika Anda menggunakan ekstensi,
      // namun di sini kita hanya menghapus dokumen utamanya.
      await _db.collection('services').doc(id).delete();
    } catch (e) {
      throw Exception('Gagal menghapus layanan: $e');
    }
  }
  //============================================================================
  // TRANSACTION API
  //============================================================================

  Future<List<Transaction>> getTransactions({
    int? year,
    int? month,
    List<TransactionStatus>? statuses,
  }) async {
    try {
      Query query = _db.collection('transactions');

      // Jika tahun dan bulan diberikan, tambahkan filter rentang waktu
      if (year != null && month != null) {
        // Ambil semua status lalu filter bulan di sisi aplikasi. Sebagian data
        // lama tidak memiliki created_at, sehingga perlu fallback ke
        // completed_at atau updated_at agar tetap muncul di laporan.
        query = query.where('status', whereIn: [
          TransactionStatus.in_progress.name,
          TransactionStatus.completed.name,
          TransactionStatus.paid.name,
        ]);
      } else if (statuses != null && statuses.isNotEmpty) {
        // Jika ada filter status, gunakan itu.
        // Firestore 'in' query supports up to 10 elements.
        // For 'in_progress' and 'completed', this is fine.
        query = query.where('status',
            whereIn: statuses.map((s) => s.name).toList());
      } else {
        // Jika tidak ada filter, cukup urutkan berdasarkan tanggal.
        // Ini adalah kasus "ambil semua" untuk ekspor.
        // Untuk memastikan semua data terambil, kita filter berdasarkan semua kemungkinan status.
        query = query.where('status', whereIn: [
          TransactionStatus.in_progress.name,
          TransactionStatus.completed.name,
          TransactionStatus.paid.name
        ]);
      }

      final transactionSnapshot = await query.get();
      var transactions = transactionSnapshot.docs.map((doc) {
        final trxData = doc.data() as Map<String, dynamic>;
        trxData['transaction_id'] = doc.id;
        return Transaction.fromMap(trxData);
      }).toList();

      if (year != null && month != null) {
        transactions = transactions.where((transaction) {
          final effectiveDate = transaction.effectiveDate;
          return effectiveDate != null &&
              effectiveDate.year == year &&
              effectiveDate.month == month;
        }).toList();
      }

      // Jika tidak ada transaksi, kembalikan list kosong
      if (transactions.isEmpty) {
        return [];
      }

      // --- POPULATE CUSTOMER DATA ---
      // 1. Kumpulkan semua customerId unik dari transaksi
      final customerIds = transactions
          .map((trx) => trx.customerId)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      // Firestore limits `whereIn` to 10 values. Fetch customer documents in
      // batches so a busy month cannot make the transaction list fail.
      final customerSnapshots = await Future.wait([
        for (var index = 0; index < customerIds.length; index += 10)
          (() {
            final query = _db.collection('customers');
            return query
                .where(
                  FieldPath.documentId,
                  whereIn: customerIds.sublist(
                    index,
                    index + 10 > customerIds.length
                        ? customerIds.length
                        : index + 10,
                  ),
                )
                .get();
          })(),
      ]);

      // 3. Buat map untuk pencarian cepat: customerId -> Customer object
      final customerMap = {
        for (final snapshot in customerSnapshots)
          for (final doc in snapshot.docs)
            doc.id: Customer.fromMap(doc.data()..['customer_id'] = doc.id)
      };

      // 4. Gabungkan data customer ke dalam setiap transaksi
      final populatedTransactions = transactions.map((trx) {
        return trx.copyWith(customer: customerMap[trx.customerId]);
      }).toList();

      // Selalu urutkan di sisi klien untuk konsistensi
      populatedTransactions.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

      return populatedTransactions;
    } catch (e) {
      throw Exception('Gagal mengambil data transaksi: $e');
    }
  }

  Future<Transaction> addTransaction(Transaction transaction) async {
    try {
      // Tambahkan data denormalisasi untuk pembacaan yang lebih efisien
      final Map<String, dynamic> transactionData =
          transaction.toMap(includeId: false, includeCreatedAt: false);
      transactionData['customer_name'] = transaction.customer?.name;
      transactionData['owner_id'] = _ownerId;
      transactionData['created_at'] = FieldValue.serverTimestamp();

      final docRef = await _db.collection('transactions').add(transactionData);
      return transaction.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Gagal menambah transaksi: $e');
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    try {
      // Saat update, pastikan data denormalisasi juga diperbarui jika perlu
      final Map<String, dynamic> transactionData =
          transaction.toMap(includeId: false);
      transactionData['customer_name'] = transaction.customer?.name;
      transactionData['owner_id'] = _ownerId;
      await _db
          .collection('transactions')
          .doc(transaction.id)
          .update(transactionData);
    } catch (e) {
      throw Exception('Gagal memperbarui transaksi: $e');
    }
  }

  Future<void> updateTransactionStatus(
    String transactionId,
    TransactionStatus status, {
    DateTime? completedAt,
    double? subtotalAmount,
    DiscountType? discountType,
    double? discountValue,
    double? discountAmount,
    String? discountNotes,
    double? totalAmount,
  }) async {
    try {
      final data = <String, dynamic>{
        'status': status.name,
        'completed_at':
            completedAt == null ? null : Timestamp.fromDate(completedAt),
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (status == TransactionStatus.paid) {
        data.addAll({
          'subtotal_amount': subtotalAmount,
          'discount_type': (discountType ?? DiscountType.none).name,
          'discount_value': discountValue ?? 0,
          'discount_amount': discountAmount ?? 0,
          'discount_notes': discountNotes,
          'total_amount': totalAmount,
        });
      }
      await _db.collection('transactions').doc(transactionId).update(data);
    } catch (e) {
      throw Exception('Gagal memperbarui status transaksi: $e');
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _db.collection('transactions').doc(id).delete();
    } catch (e) {
      throw Exception('Gagal menghapus transaksi: $e');
    }
  }
}

/*
  Struktur data yang disarankan di Firestore:

  /customers/{customerId}
    - full_name: "John Doe"
    - phone_number: "08123456789"
    - alamat: "Jalan..."
    - created_at: Timestamp
    - updated_at: Timestamp

  /services/{serviceId}
    - service_name: "Cuci Kering"
    - description: "Pakaian dicuci dan dikeringkan"
    - prices: [
        { price_id: "p1", price: 15000, notes: "Reguler" },
        { price_id: "p2", price: 25000, notes: "Express" }
      ]
    - created_at: Timestamp
    - updated_at: Timestamp

  /transactions/{transactionId}
    - customer_id: "..." (Referensi ke /customers/{customerId})
    - service_id: "..." (Referensi ke /services/{serviceId})
    - price_id: "p1"
    - transaction_source: "Workshop" // Baru: Workshop, Dibarbers, Antar-jemput
    - quantity: 2
    - total_amount: 30000
    - status: "in_progress"
    - transaction_notes: "Jangan pakai pewangi"
    - created_at: Timestamp
    // Data denormalisasi untuk efisiensi query
    - customer_name: "John Doe"
    - service_name: "Cuci Kering"
    - completed_at: Timestamp (null jika belum selesai)
    - updated_at: Timestamp
*/

/*
  Catatan Penting untuk Aturan Keamanan (Security Rules) Firestore:

  Untuk memastikan hanya pengguna terautentikasi yang bisa mengakses data,
  Anda perlu mengatur Security Rules di Firebase Console.
  Contoh sederhana:

  rules_version = '2';
  service cloud.firestore {
    match /databases/{database}/documents {
      // Izinkan baca/tulis jika pengguna sudah login
      match /{document=**} {
        allow read, write: if request.auth != null;
      }
    }
  }

  Ini adalah aturan dasar. Untuk produksi, Anda mungkin perlu aturan yang lebih spesifik
  per koleksi untuk keamanan yang lebih baik.
*/
