class Bookmark {
  final String id;
  final String title;
  final String url;
  final String? faviconUrl;
  final DateTime createdAt;

  Bookmark({
    required this.id,
    required this.title,
    required this.url,
    this.faviconUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'url': url,
    'faviconUrl': faviconUrl,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory Bookmark.fromMap(Map<String, dynamic> map) => Bookmark(
    id: map['id'] as String,
    title: map['title'] as String,
    url: map['url'] as String,
    faviconUrl: map['faviconUrl'] as String?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
  );
}
