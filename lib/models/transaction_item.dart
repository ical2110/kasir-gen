class TransactionItem {
  final String serviceId;
  final String serviceName;
  final String priceId;
  final String? priceNotes;
  final double price;
  final int quantity;
  final double subtotal;

  TransactionItem({
    required this.serviceId,
    required this.serviceName,
    required this.priceId,
    this.priceNotes,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      serviceId: map['service_id'] ?? '',
      serviceName: map['service_name'] ?? '',
      priceId: map['price_id'] ?? '',
      priceNotes: map['price_notes'],
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'service_id': serviceId,
      'service_name': serviceName,
      'price_id': priceId,
      'price_notes': priceNotes,
      'price': price,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }
}
