import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/customer.dart';
import '../models/service.dart';
import '../models/transaction.dart';

class ApiService {
  // Gunakan --dart-define untuk menentukan BASE_URL saat build.
  // Contoh: flutter run --dart-define=BASE_URL=http://10.0.2.2/laundry_api
  static const _baseUrl = String.fromEnvironment('BASE_URL',
      defaultValue: 'http://localhost/laundry_api');

  // Fungsi untuk mengambil (GET) daftar pelanggan dari API
  Future<List<Customer>> getCustomers() async {
    final response = await http.get(Uri.parse('$_baseUrl/get_customers.php'));

    if (response.statusCode == 200) {
      // Jika server mengembalikan respons 200 OK,
      // parse JSON.
      List<dynamic> body = json.decode(response.body);
      List<Customer> customers =
          body.map((dynamic item) => Customer.fromMap(item)).toList();
      return customers;
    } else {
      // Jika server tidak mengembalikan respons 200 OK,
      // lempar sebuah exception.
      throw Exception('Gagal memuat data pelanggan');
    }
  }

  // Fungsi untuk menambah pelanggan (POST)
  Future<void> addCustomer(Customer customer) async {
    final response = await http.post(
      Uri.parse(
          '$_baseUrl/add_customers.php'), // Disesuaikan dengan nama file Anda
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(
          customer.toMap(includeId: false)), // Jangan kirim ID saat menambah
    );

    // 201 adalah status 'Created' yang umum untuk POST yang berhasil
    if (response.statusCode != 201) {
      // Jika server tidak mengembalikan respons sukses, lempar exception.
      // Anda bisa membaca response.body untuk pesan error dari server.
      throw Exception(
          'Gagal menambah pelanggan. Status: ${response.statusCode}, Body: ${response.body}');
    }
    // Tidak perlu mengembalikan apa-apa jika hanya konfirmasi sukses
  }

  // Fungsi untuk mengupdate pelanggan (PUT)
  Future<void> updateCustomer(Customer customer) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/update_customer.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(customer.toMap()),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Gagal mengupdate pelanggan. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // Fungsi untuk menghapus pelanggan (DELETE)
  Future<void> deleteCustomer(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/delete_customer.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      // Kirim ID dalam body, sesuai dengan contoh API PHP yang umum
      body: jsonEncode(<String, String>{'customer_id': id}),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Gagal menghapus pelanggan. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // --- FUNGSI UNTUK MANAJEMEN LAYANAN ---

  // Mengambil (GET) daftar layanan
  Future<List<Service>> getServices() async {
    final response = await http.get(Uri.parse('$_baseUrl/get_services.php'));

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      List<Service> services =
          body.map((dynamic item) => Service.fromMap(item)).toList();
      return services;
    } else {
      throw Exception(
          'Gagal memuat data layanan. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // Menambah layanan baru (POST)
  Future<void> addService(Service service) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/add_service.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(service.toMap(includeId: false)),
    );

    if (response.statusCode != 201) {
      throw Exception(
          'Gagal menambah layanan. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // TODO: Buat fungsi untuk mengupdate layanan (PUT)
  Future<void> updateService(Service service) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/update_service.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(service.toMap(includeId: true)),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Gagal mengupdate layanan. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // TODO: Buat fungsi untuk menghapus layanan (DELETE)
  Future<void> deleteService(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/delete_service.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      // Kirim ID dalam body, sesuai dengan skrip PHP
      body: jsonEncode(<String, String>{'service_id': id}),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Gagal menghapus layanan. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // --- FUNGSI UNTUK MANAJEMEN TRANSAKSI ---

  // Mengambil (GET) daftar transaksi
  Future<List<Transaction>> getTransactions() async {
    final response =
        await http.get(Uri.parse('$_baseUrl/get_transactions.php'));

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      List<Transaction> transactions =
          body.map((dynamic item) => Transaction.fromMap(item)).toList();
      return transactions;
    } else {
      throw Exception(
          'Gagal memuat data transaksi. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // Menambah transaksi baru (POST)
  Future<void> addTransaction(Transaction transaction) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/add_transactions.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(transaction.toMap(includeId: false)),
    );

    if (response.statusCode != 201) {
      throw Exception(
          'Gagal menambah transaksi. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // Mengupdate transaksi (PUT)
  Future<void> updateTransaction(Transaction transaction) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/update_transactions.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(transaction.toMap(includeId: true)),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Gagal mengupdate transaksi. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // Menghapus transaksi (DELETE)
  Future<void> deleteTransaction(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/delete_transactions.php'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{'transaction_id': id}),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Gagal menghapus transaksi. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }
}
