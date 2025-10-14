import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:kasir_gen/models/customer.dart';
import 'package:kasir_gen/models/service.dart';
import 'package:kasir_gen/models/transaction.dart';

class ApiService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  //============================================================================
  // CUSTOMER API
  //============================================================================

  Future<List<Customer>> getCustomers() async {
    try {
      final snapshot = await _db.collection('customers').get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['customer_id'] = doc.id; // Tambahkan ID dokumen ke data
        return Customer.fromMap(data);
      }).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data pelanggan: $e');
    }
  }

  Future<Customer> addCustomer(Customer customer) async {
    try {
      // Firestore akan generate ID secara otomatis
      final docRef = await _db
          .collection('customers')
          .add(customer.toMap(includeId: false));
      // Mengembalikan customer dengan ID yang sudah dibuat menggunakan copyWith
      return customer.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Gagal menambah pelanggan: $e');
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    try {
      await _db
          .collection('customers')
          .doc(customer.id)
          .update(customer.toMap(includeId: false));
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
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['service_id'] = doc.id;
        return Service.fromMap(data);
      }).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data layanan: $e');
    }
  }

  Future<Service> addService(Service service) async {
    try {
      final docRef =
          await _db.collection('services').add(service.toMap(includeId: false));
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
      await _db
          .collection('services')
          .doc(service.id)
          .update(service.toMap(includeId: false));
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
        final DateTime startDate = DateTime(year, month, 1);
        // Akhir bulan adalah awal dari bulan berikutnya
        final DateTime endDate = DateTime(year, month + 1, 1);

        // Saat menggunakan filter rentang, orderBy pertama harus pada field yang sama.
        query = query
            .where('created_at',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('created_at', isLessThan: Timestamp.fromDate(endDate));
        // Tidak perlu orderBy di sini jika akan diurutkan di client
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
      final transactions = transactionSnapshot.docs.map((doc) {
        final trxData = doc.data() as Map<String, dynamic>;
        trxData['transaction_id'] = doc.id;
        return Transaction.fromMap(trxData);
      }).toList();

      // Jika tidak ada transaksi, kembalikan list kosong
      if (transactions.isEmpty) {
        return [];
      }

      // --- POPULATE CUSTOMER DATA ---
      // 1. Kumpulkan semua customerId unik dari transaksi
      final customerIds =
          transactions.map((trx) => trx.customerId).toSet().toList();

      // 2. Ambil semua data customer yang relevan dalam satu query
      final customerSnapshot = await _db
          .collection('customers')
          .where(FieldPath.documentId, whereIn: customerIds)
          .get();

      // 3. Buat map untuk pencarian cepat: customerId -> Customer object
      final customerMap = {
        for (var doc in customerSnapshot.docs)
          doc.id: Customer.fromMap(
              (doc.data() as Map<String, dynamic>)..['customer_id'] = doc.id)
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
          transaction.toMap(includeId: false);
      transactionData['customer_name'] = transaction.customer?.name;

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
      await _db
          .collection('transactions')
          .doc(transaction.id)
          .update(transactionData);
    } catch (e) {
      throw Exception('Gagal memperbarui transaksi: $e');
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
