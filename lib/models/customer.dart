import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String name;
  final String phone;
  final String? alamat;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.alamat,
    this.createdAt,
    this.updatedAt,
  });

  // Metode untuk mengkonversi objek Customer menjadi Map (untuk disimpan ke database)
  Map<String, dynamic> toMap({bool includeId = true}) {
    final map = {
      // Gunakan nama kolom dari database Anda saat mengirim data ke API
      'full_name': name,
      'phone_number': phone,
      'alamat': alamat,
      // Firestore akan secara otomatis mengkonversi DateTime ke Timestamp
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (includeId) {
      map['customer_id'] = id;
    }
    return map;
  }

  // Metode untuk membuat objek Customer dari Map yang diambil dari database
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['customer_id']?.toString() ?? '',
      name: map['full_name'] ?? '',
      phone: map['phone_number'] ?? '',
      alamat: map['alamat'],
      // Konversi Timestamp dari Firestore menjadi DateTime
      createdAt: (map['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  // Metode copyWith untuk membuat salinan objek dengan beberapa field yang diubah
  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? alamat,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      alamat: alamat ?? this.alamat,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Override operator == dan hashCode agar perbandingan objek berdasarkan ID
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Customer && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
