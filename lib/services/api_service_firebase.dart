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
        final data = doc.data();
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
        final data = doc.data();
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
      // Kita perlu membuat objek baru dengan ID yang dihasilkan
      // karena copyWith tidak ada di model Service.
      return Service(
          id: docRef.id,
          name: service.name,
          description: service.description,
          prices: service.prices);
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

  //============================================================================
  // TRANSACTION API
  //============================================================================

  Future<List<Transaction>> getTransactions() async {
    try {
      // Mengambil transaksi dengan data customer dan service yang sudah didenormalisasi.
      // Ini jauh lebih efisien karena hanya memerlukan satu panggilan ke database.
      final transactionSnapshot = await _db.collection('transactions').get();
      final transactions = transactionSnapshot.docs.map((doc) {
        final trxData = doc.data();
        trxData['transaction_id'] = doc.id;
        // Asumsi model Transaction.fromMap dapat menangani data denormalisasi
        // yang mungkin sudah ada di dalam trxData.
        return Transaction.fromMap(trxData);
      }).toList();

      return transactions;
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
      transactionData['service_name'] = transaction.service?.name;

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
      transactionData['service_name'] = transaction.service?.name;
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
