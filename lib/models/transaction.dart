import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kasir_gen/models/customer.dart';
import 'package:kasir_gen/models/transaction_item.dart';

enum TransactionStatus {
  in_progress,
  completed,
  paid,
}

String statusToDisplayString(TransactionStatus status) {
  switch (status) {
    case TransactionStatus.in_progress:
      return 'Dalam Proses';
    case TransactionStatus.completed:
      return 'Selesai';
    case TransactionStatus.paid:
      return 'Dibayar';
    default:
      return 'Tidak Diketahui';
  }
}

class Transaction {
  final String id;
  final String customerId;
  final List<TransactionItem> items;
  final double totalAmount;
  final TransactionStatus status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final DateTime? updatedAt;
  final String? transactionSource; // <-- Field baru ditambahkan di sini

  // Data denormalisasi (tidak disimpan langsung, tapi bisa di-populate)
  final Customer? customer;

  Transaction({
    required this.id,
    required this.customerId,
    required this.items,
    required this.totalAmount,
    required this.status,
    this.notes,
    this.createdAt,
    this.completedAt,
    this.updatedAt,
    this.transactionSource, // <-- Field baru ditambahkan di sini
    this.customer,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    // Konversi status dari String ke Enum
    TransactionStatus status;
    switch (map['status']) {
      case 'in_progress':
        status = TransactionStatus.in_progress;
        break;
      case 'completed':
        status = TransactionStatus.completed;
        break;
      case 'paid':
        status = TransactionStatus.paid;
        break;
      default:
        status = TransactionStatus.in_progress; // Default
    }

    return Transaction(
      id: map['transaction_id'] ?? '',
      customerId: map['customer_id'] ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => TransactionItem.fromMap(item))
              .toList() ??
          [],
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: status,
      notes: map['transaction_notes'],
      createdAt: (map['created_at'] as Timestamp?)?.toDate(),
      completedAt: (map['completed_at'] as Timestamp?)?.toDate(),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate(),
      transactionSource: map['transaction_source'], // <-- Ambil data dari map
      // Customer di-populate secara terpisah
    );
  }

  Map<String, dynamic> toMap({
    bool includeId = true,
    bool includeCreatedAt = true,
  }) {
    final map = {
      if (includeId) 'transaction_id': id,
      'customer_id': customerId,
      'items': items.map((item) => item.toMap()).toList(),
      'total_amount': totalAmount,
      'status': status.name, // Konversi enum ke string
      'transaction_notes': notes,
      'completed_at':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'updated_at': FieldValue.serverTimestamp(),
      'transaction_source': transactionSource, // <-- Tambahkan data ke map
    };
    if (includeCreatedAt) {
      map['created_at'] = createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp();
    }
    return map;
  }

  Transaction copyWith({
    String? id,
    String? customerId,
    List<TransactionItem>? items,
    double? totalAmount,
    TransactionStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? updatedAt,
    String? transactionSource, // <-- Field baru ditambahkan di sini
    Customer? customer,
  }) {
    return Transaction(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      transactionSource: transactionSource ??
          this.transactionSource, // <-- Field baru ditambahkan di sini
      customer: customer ?? this.customer,
    );
  }
}
