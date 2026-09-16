class InventoryItem {
  final int id;
  final String name;
  final double quantity;
  final String unit;
  final int? categoryId;
  final String? categoryName;
  final DateTime? expiryDate;
  final double? autoDecrementAmount;
  final int? autoDecrementIntervalDays;

  InventoryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.categoryId,
    this.categoryName,
    this.expiryDate,
    this.autoDecrementAmount,
    this.autoDecrementIntervalDays,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'],
      name: json['name'],
      quantity: double.parse(json['quantity'].toString()),
      unit: json['unit'] ?? '',
      categoryId: json['category'],
      categoryName: json['category_name'],
      expiryDate: json['expiry_date'] != null
                  ? DateTime.tryParse(json['expiry_date'])
                  : null,
      autoDecrementAmount: json['auto_decrement_amount'] != null
                          ? double.parse(json['auto_decrement_amount'].toString())
                          : null,
      autoDecrementIntervalDays: json['auto_decrement_interval_days'] != null 
                                  ? int.parse(json['auto_decrement_interval_days'].toString())
                                  : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'category': categoryId,
    'expiry_date': expiryDate?.toIso8601String().split('T').first,
    'auto_decrement_amount': autoDecrementAmount,
    'auto_decrement_interval_days': autoDecrementIntervalDays,
  };

}