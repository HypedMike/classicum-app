import 'dart:convert';

import 'package:classicum_admin/core/network/api_client.dart';
import 'package:classicum_admin/core/network/uploads.dart';
import 'package:classicum_admin/core/pagination.dart';
import 'package:classicum_admin/features/news/data/news_item.dart';

class NewsRepository {
  NewsRepository(this.api);

  final ApiClient api;

  Future<Paginated<NewsItem>> news({int page = 1, int limit = 10}) async {
    final data = await api.getJson(
      '/api/news',
      query: {'page': '$page', 'limit': '$limit'},
    ) as Map<String, dynamic>;
    final items = (data['data'] as List)
        .map((e) => NewsItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = (data['total'] as num).toInt();
    return Paginated(
      items: items,
      page: page,
      total: total,
      hasMore: page * limit < total,
    );
  }

  Future<void> createNews({
    required String title,
    required String content,
    List<UploadImage> images = const [],
  }) async {
    await api.multipart(
      'POST',
      '/api/news',
      fields: {'title': title, 'content': content, 'mainImageIndex': '0'},
      files: () => [for (final i in images) multipartFile('images[]', i)],
    );
  }

  /// Updates title/content and keeps the existing images as they are.
  Future<void> updateNews(
    NewsItem item, {
    required String title,
    required String content,
  }) async {
    await api.multipart(
      'PUT',
      '/api/news/${item.id}',
      fields: {
        'title': title,
        'content': content,
        'keepImages': jsonEncode(
          item.images.map((i) => i.toKeepJson()).toList(),
        ),
        'newImagesMeta': '[]',
      },
    );
  }

  Future<void> deleteNews(String id) => api.delete('/api/news/$id');

  String imageUrl(String id) => api.fileUrl(id);
}
