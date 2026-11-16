class TransactionEntry {
  final int id, itemId;
  final String itemName, itemUnit, changeType, source, note;
  final double delta;
  final double? unitPrice;
  final DateTime createdAt;
  final String? username;

  const TransactionEntry({
    required this.id, required this.itemId, required this.itemName,
    required this.itemUnit, required this.changeType, required this.source,
    required this.note, required this.delta, required this.createdAt,
    this.unitPrice, this.username,
  });

  factory TransactionEntry.fromJson(Map<String, dynamic> j) => TransactionEntry(
        id: j['id'],
        itemId: j['item'],
        itemName: j['item_name'] ?? '',
        itemUnit: j['item_unit'] ?? '',
        changeType: j['change_type'],
        source: j['source'] ?? 'manual',
        note: j['note'] ?? '',
        delta: double.parse(j['quantity_delta'].toString()),
        unitPrice: j['unit_price'] != null
            ? double.tryParse(j['unit_price'].toString())
            : null,
        createdAt: DateTime.parse(j['created_at']).toLocal(),
        username: j['username'],
      );
}