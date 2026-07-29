import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kasir_gen/models/customer.dart';
import 'package:kasir_gen/models/transaction_item.dart';

enum TransactionStatus {
  // Nama ini adalah nilai persisten di Firestore dan tidak boleh diubah.
  // ignore: constant_identifier_names
  in_progress,
  completed,
  paid,
}

enum DiscountType {
  none,
  percent,
  fixed,
}

String discountTypeToDisplayString(DiscountType type) {
  switch (type) {
    case DiscountType.none:
      return 'Tanpa diskon';
    case DiscountType.percent:
      return 'Persentase';
    case DiscountType.fixed:
      return 'Nominal rupiah';
  }
}

double calculateDiscountAmount(
  double subtotal,
  DiscountType type,
  double value,
) {
  if (subtotal <= 0 || value <= 0 || type == DiscountType.none) return 0;
  final amount = type == DiscountType.percent
      ? subtotal * value.clamp(0, 100) / 100
      : value;
  return amount.clamp(0, subtotal).toDouble();
}

String statusToDisplayString(TransactionStatus status) {
  switch (status) {
    case TransactionStatus.in_progress:
      return 'Dalam Proses';
    case TransactionStatus.completed:
      return 'Selesai';
    case TransactionStatus.paid:
      return 'Dibayar';
  }
}

class Transaction {
  final String id;
  final String customerId;
  final String creatorId;
  final String creatorName;
  final List<TransactionItem> items;
  final double subtotalAmount;
  final DiscountType discountType;
  final double discountValue;
  final double discountAmount;
  final String? discountNotes;
  final double totalAmount;
  final TransactionStatus status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final DateTime? updatedAt;
  final String? transactionSource; // <-- Field baru ditambahkan di sini

  // Data denormalisasi (tidak disimpan langsung, tapi bisa di-populate)
  final Customer? customer;

  DateTime? get effectiveDate => createdAt ?? completedAt ?? updatedAt;

  Transaction({
    required this.id,
    required this.customerId,
    this.creatorId = '',
    this.creatorName = '',
    required this.items,
    required this.totalAmount,
    double? subtotalAmount,
    this.discountType = DiscountType.none,
    this.discountValue = 0,
    this.discountAmount = 0,
    this.discountNotes,
    required this.status,
    this.notes,
    this.createdAt,
    this.completedAt,
    this.updatedAt,
    this.transactionSource, // <-- Field baru ditambahkan di sini
    this.customer,
  }) : subtotalAmount = subtotalAmount ?? totalAmount;

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

    final totalAmount = (map['total_amount'] as num?)?.toDouble() ?? 0.0;
    final discountType = DiscountType.values.firstWhere(
      (type) => type.name == map['discount_type'],
      orElse: () => DiscountType.none,
    );

    return Transaction(
      id: map['transaction_id'] ?? '',
      customerId: map['customer_id'] ?? '',
      creatorId: map['owner_id'] ?? '',
      creatorName: map['created_by_name'] ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => TransactionItem.fromMap(item))
              .toList() ??
          [],
      subtotalAmount:
          (map['subtotal_amount'] as num?)?.toDouble() ?? totalAmount,
      discountType: discountType,
      discountValue: (map['discount_value'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
      discountNotes: map['discount_notes'],
      totalAmount: totalAmount,
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
      'subtotal_amount': subtotalAmount,
      'discount_type': discountType.name,
      'discount_value': discountValue,
      'discount_amount': discountAmount,
      'discount_notes': discountNotes,
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
    String? creatorId,
    String? creatorName,
    List<TransactionItem>? items,
    double? subtotalAmount,
    DiscountType? discountType,
    double? discountValue,
    double? discountAmount,
    String? discountNotes,
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
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      items: items ?? this.items,
      subtotalAmount: subtotalAmount ?? this.subtotalAmount,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      discountAmount: discountAmount ?? this.discountAmount,
      discountNotes: discountNotes ?? this.discountNotes,
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
