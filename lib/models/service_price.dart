import 'package:cloud_firestore/cloud_firestore.dart';

class ServicePrice {
  final String priceId;
  final String serviceId;
  final double price;
  final String? notes; // Contoh: 'per kg', 'per potong', 'express'
  final DateTime? createdAt;

  ServicePrice({
    required this.priceId,
    required this.serviceId,
    required this.price,
    this.notes,
    this.createdAt,
  });

  factory ServicePrice.fromMap(Map<String, dynamic> map) {
    return ServicePrice(
      priceId: map['price_id']?.toString() ?? '',
      serviceId: map['service_id']?.toString() ?? '',
      price: double.tryParse(map['price'].toString()) ?? 0.0,
      notes: map['notes'],
      createdAt: (map['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap(
      {bool includeId = true, bool includeServiceId = true}) {
    final map = {
      'price': price,
      'notes': notes,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
    if (includeId) {
      map['price_id'] = priceId;
    }
    if (includeServiceId) {
      map['service_id'] = serviceId;
    }
    return map;
  }

  // Override operator == dan hashCode agar perbandingan objek berdasarkan ID
  // Ini penting untuk Dropdown di form transaksi
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServicePrice &&
          runtimeType == other.runtimeType &&
          priceId == other.priceId;

  @override
  int get hashCode => priceId.hashCode;
}
