class NewsImage {
  const NewsImage({
    required this.fileId,
    required this.isMain,
    required this.order,
  });

  factory NewsImage.fromJson(Map<String, dynamic> json) => NewsImage(
    fileId: json['fileId'] as String,
    isMain: json['isMain'] as bool? ?? false,
    order: (json['order'] as num?)?.toInt() ?? 0,
  );

  final String fileId;
  final bool isMain;
  final int order;

  Map<String, dynamic> toKeepJson() => {
    'fileId': fileId,
    'isMain': isMain,
    'order': order,
  };
}

class NewsItem {
  const NewsItem({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.images = const [],
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    final images =
        ((json['newsImages'] as List?) ?? const [])
            .map((e) => NewsImage.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    return NewsItem(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      images: images,
    );
  }

  final String id;
  final String title;

  /// HTML produced by the website's rich text editor.
  final String content;
  final DateTime createdAt;
  final List<NewsImage> images;

  String? get mainImageId {
    if (images.isEmpty) return null;
    return images
        .firstWhere((i) => i.isMain, orElse: () => images.first)
        .fileId;
  }
}
