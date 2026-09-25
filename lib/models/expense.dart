class Expense {
  final int id;
  final String description;
  final double amount;
  final DateTime date;
  final int? categoryId;
  final String? categoryName;
  final int? itemId;
  final String? itemName;
  final String source;

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    this.categoryId,
    this.categoryName,
    this.itemId,
    this.itemName,
    this.source = 'manual',
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      description: json['description'] ?? '',
      amount: json['amount'] is String
          ? double.parse(json['amount'])
          : (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      categoryId: json['category'],
      categoryName: json['category_name'],
      itemId: json['item'],
      itemName: json['item_name'],
      source: json['source'] ?? 'manual',
    );
  }

  Map<String, dynamic> toJson() => {
    'description': description,
    'amount': amount,
    'date': date.toIso8601String().split('T').first,
    'category': categoryId,
    'source': source,
  };
}