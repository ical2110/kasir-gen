import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kasir_gen/models/customer.dart';
import 'package:kasir_gen/models/service.dart';

// Enum untuk status transaksi agar lebih aman dan terstruktur
enum TransactionStatus { in_progress, completed, paid }

// Helper untuk konversi string ke enum dan sebaliknya
TransactionStatus statusFromString(String status) {
  return TransactionStatus.values.firstWhere(
    (e) => e.toString().split('.').last == status,
    orElse: () => TransactionStatus.in_progress,
  );
}

String statusToString(TransactionStatus status) {
  return status.toString().split('.').last;
}

// Helper baru untuk menampilkan status dengan format yang lebih baik di UI
String statusToDisplayString(TransactionStatus status) {
  switch (status) {
    case TransactionStatus.in_progress:
      return 'In Progress';
    case TransactionStatus.completed:
      return 'Completed';
    case TransactionStatus.paid:
      return 'Paid';
  }
}

class Transaction {
  final String id;
  final String customerId;
  final String serviceId;
  final String priceId; // Tambahkan priceId
  final TransactionStatus status;
  final int quantity;
  final double totalAmount;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt; // Tambahkan field untuk waktu selesai

  // Opsional: Untuk menampung data lengkap customer dan service saat join query
  final Customer? customer;
  final Service? service;

  Transaction({
    required this.id,
    required this.customerId,
    required this.serviceId,
    required this.priceId,
    required this.status,
    required this.quantity,
    required this.totalAmount,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.customer,
    this.service,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['transaction_id']?.toString() ?? '',
      customerId: map['customer_id']?.toString() ?? '',
      serviceId: map['service_id']?.toString() ?? '',
      priceId: map['price_id']?.toString() ?? '', // Ambil price_id dari map
      status: statusFromString(map['status'] ?? 'pending'),
      quantity: int.tryParse(map['quantity']?.toString() ?? '0') ?? 0,
      totalAmount:
          double.tryParse(map['total_amount']?.toString() ?? '0.0') ?? 0.0,
      notes: map['transaction_notes'],
      createdAt: (map['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate(),
      completedAt: (map['completed_at'] as Timestamp?)?.toDate(),
      // Cek apakah data denormalisasi (customer_name, service_name) ada di map.
      // Jika ada, buat objek Customer/Service sederhana hanya dengan nama.
      // Ini berguna untuk tampilan di UI tanpa perlu query tambahan.
      customer: map.containsKey('customer_name') && map['customer_name'] != null
          ? Customer(
              id: map['customer_id'] ?? '',
              name: map['customer_name'],
              phone: '')
          : null,
      service: map.containsKey('service_name') && map['service_name'] != null
          ? Service.fromMap({'service_name': map['service_name']})
          : null,
    );
  }

  Map<String, dynamic> toMap({bool includeId = true}) {
    final map = {
      'customer_id': customerId,
      'service_id': serviceId,
      'price_id': priceId, // Kirim price_id ke API
      'status': statusToString(status),
      'quantity': quantity,
      'total_amount': totalAmount,
      'transaction_notes': notes,
      // Gunakan Timestamp untuk konsistensi di Firestore
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'completed_at':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
    if (includeId) {
      map['transaction_id'] = id;
    }
    return map;
  }

  // Metode copyWith untuk membuat salinan objek dengan beberapa field yang diubah
  Transaction copyWith({
    String? id,
    String? customerId,
    String? serviceId,
    String? priceId,
    TransactionStatus? status,
    int? quantity,
    double? totalAmount,
    String? notes,
    Customer? customer,
    DateTime? createdAt, // Tambahkan parameter yang hilang
    DateTime? updatedAt,
    DateTime? completedAt, // Tambahkan parameter baru
    Service? service,
  }) {
    return Transaction(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      serviceId: serviceId ?? this.serviceId,
      priceId: priceId ?? this.priceId,
      status: status ?? this.status,
      quantity: quantity ?? this.quantity,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      customer: customer ?? this.customer,
      service: service ?? this.service,
    );
  }
}
