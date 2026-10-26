class Tag {
  final int id;
  final String name;
  final int itemCount;

  const Tag({required this.id, required this.name, this.itemCount = 0});

  factory Tag.fromJson(Map<String, dynamic> json) => Tag(
    id: json['id'],
    name: json['name'],
    itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
  );

  // Identity by id so selection checks work across refetches.
  @override
  bool operator ==(Object other) => other is Tag && other.id == id;

  @override
  int get hashCode => id.hashCode;
}