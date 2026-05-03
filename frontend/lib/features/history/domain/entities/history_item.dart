enum HistoryItemType { recognition, dictionary, translation }

class HistoryItem {
  final String id;
  final String text;
  final HistoryItemType type;
  final DateTime createdAt;

  const HistoryItem({
    required this.id,
    required this.text,
    required this.type,
    required this.createdAt,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> j) => HistoryItem(
        id: j['id'] as String,
        text: j['text'] as String,
        type: _parseType(j['type'] as String? ?? 'RECOGNITION'),
        createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
      );

  static HistoryItemType _parseType(String raw) => switch (raw) {
        'DICTIONARY' => HistoryItemType.dictionary,
        'TRANSLATION' => HistoryItemType.translation,
        _ => HistoryItemType.recognition,
      };
}
