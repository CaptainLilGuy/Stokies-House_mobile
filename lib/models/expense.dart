class Expense {
  final int id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? note;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'], 
      title: json['title'], 
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] ?? 'Other',
      date: DateTime.parse(json['data']),
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'amount': amount,
    'category': category,
    'date': date.toIso8601String().split('T').first,
    'note': note,
  };
}