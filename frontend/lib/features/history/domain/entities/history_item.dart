class HistoryItem {
  final String id;
  final String text;
  final DateTime createdAt;

  const HistoryItem({
    required this.id,
    required this.text,
    required this.createdAt,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> j) => HistoryItem(
        id: j['id'] as String,
        text: j['text'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
      );
}
