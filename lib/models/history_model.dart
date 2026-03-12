class HistoryEntry {
  final String id;
  final String title;
  final String url;
  final DateTime visitedAt;

  HistoryEntry({
    required this.id,
    required this.title,
    required this.url,
    required this.visitedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'url': url,
    'visitedAt': visitedAt.millisecondsSinceEpoch,
  };

  factory HistoryEntry.fromMap(Map<String, dynamic> map) => HistoryEntry(
    id: map['id'] as String,
    title: map['title'] as String,
    url: map['url'] as String,
    visitedAt: DateTime.fromMillisecondsSinceEpoch(map['visitedAt'] as int),
  );
}
