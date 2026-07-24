import 'package:cloud_firestore/cloud_firestore.dart';
import 'service_price.dart';

class Service {
  final String id;
  final String name;
  final String? description;
  final List<ServicePrice> prices; // Menampung daftar harga
  final DateTime? createdAt;
  final DateTime? updatedAt; // Sesuai dengan 'update_at' di tabel Anda

  Service({
    required this.id,
    required this.name,
    this.description,
    this.prices = const [],
    this.createdAt,
    this.updatedAt,
  });

  // Konversi dari Map (JSON) ke objek Service
  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['service_id']?.toString() ?? '',
      name: map['service_name'] ?? '',
      description: map['description'],
      // Asumsikan API akan mengirimkan daftar harga dalam key 'prices'
      prices: map['prices'] != null && map['prices'] is List
          ? (map['prices'] as List)
              .map((priceMap) => ServicePrice.fromMap(priceMap))
              .toList()
          : [],
      createdAt: (map['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  // Konversi dari objek Service ke Map (untuk dikirim sebagai JSON)
  Map<String, dynamic> toMap({
    bool includeId = true,
    bool includeCreatedAt = true,
  }) {
    final map = {
      'service_name': name,
      'description': description,
      // Sertakan daftar harga, ubah setiap objek ServicePrice menjadi Map
      'prices': prices
          // `service_id` belongs to the parent document, but each price needs
          // its own stable ID for dropdown selection and transaction history.
          .map((price) => price.toMap(includeId: true, includeServiceId: false))
          .toList(),
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (includeCreatedAt) {
      map['created_at'] = createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp();
    }
    if (includeId) {
      map['service_id'] = id;
    }
    return map;
  }

  // Override operator == dan hashCode agar perbandingan objek berdasarkan ID
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Service && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
