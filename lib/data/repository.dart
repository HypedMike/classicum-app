import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'api_client.dart';
import 'models.dart';

/// Picked image, ready to be uploaded.
class UploadImage {
  const UploadImage({required this.path, required this.filename});

  final String path;
  final String filename;
}

/// All the admin operations the app performs against the website.
class AdminRepository {
  AdminRepository(this.api);

  final ApiClient api;

  // --- auth ---------------------------------------------------------------
  Future<AdminUser> login(String email, String password) async =>
      AdminUser.fromJson(await api.login(email.trim().toLowerCase(), password));

  Future<AdminUser?> currentUser() async {
    if (!await api.hasSession()) return null;
    try {
      final data = await api.getJson('/api/auth/me') as Map<String, dynamic>;
      return AdminUser.fromJson(data['user'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.isUnauthorized) return null;
      rethrow;
    }
  }

  Future<void> logout() => api.logout();

  // --- eventi -------------------------------------------------------------
  Future<List<Evento>> events() async {
    final data = await api.getJson('/api/eventi') as List;
    return data.map((e) => Evento.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createEvent({
    required String titolo,
    required String descrizione,
    required DateTime data,
    required String luogo,
    UploadImage? image,
  }) async {
    await api.multipart(
      'POST',
      '/api/eventi',
      fields: {
        'titolo': titolo,
        'descrizione': descrizione,
        'data': data.toUtc().toIso8601String(),
        'luogo': luogo,
      },
      files: image == null ? null : () => [_file('image', image)],
    );
  }

  Future<void> deleteEvent(String id) => api.delete('/api/eventi/$id');

  // --- news ---------------------------------------------------------------
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
      files: () => [for (final i in images) _file('images[]', i)],
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

  // --- comunicati ---------------------------------------------------------
  Future<List<Comunicato>> comunicati() async {
    final data = await api.getJson('/api/comunitcati') as List;
    return data
        .map((e) => Comunicato.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createComunicato({
    required String title,
    required String description,
    required DateTime date,
  }) => api.sendJson('POST', '/api/comunitcati', {
    'title': title,
    'description': description,
    'date': date.toUtc().toIso8601String(),
  });

  Future<void> updateComunicato(
    String id, {
    required String title,
    required String description,
    required DateTime date,
  }) => api.sendJson('PUT', '/api/comunitcati/$id', {
    'title': title,
    'description': description,
    'date': date.toUtc().toIso8601String(),
  });

  Future<void> deleteComunicato(String id) =>
      api.delete('/api/comunitcati/$id');

  // --- messaggi (contatti) ------------------------------------------------
  Future<Paginated<ContactMessage>> messages({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    final data = await api.getJson(
      '/api/contact',
      query: {
        'page': '$page',
        'pageSize': '$pageSize',
        if (search != null && search.isNotEmpty) 'search': search,
      },
    ) as Map<String, dynamic>;
    return Paginated(
      items: (data['items'] as List)
          .map((e) => ContactMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: page,
      total: (data['total'] as num).toInt(),
      hasMore: page < (data['totalPages'] as num).toInt(),
    );
  }

  Future<void> deleteMessage(String id) => api.delete('/api/contact/$id');

  // --- moduli -------------------------------------------------------------
  Future<Paginated<FormDefinition>> forms({
    int page = 1,
    int pageSize = 20,
  }) async {
    final data = await api.getJson(
      '/api/form',
      query: {'page': '$page', 'pageSize': '$pageSize'},
    ) as Map<String, dynamic>;
    return Paginated(
      items: (data['items'] as List)
          .map((e) => FormDefinition.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: page,
      total: (data['total'] as num).toInt(),
      hasMore: page < (data['totalPages'] as num).toInt(),
    );
  }

  Future<FormDefinition> setFormPublished(
    FormDefinition form,
    bool published,
  ) async => FormDefinition.fromJson(
    await api.sendJson(
      'PUT',
      '/api/form/${form.id}',
      form.toUpdateJson(published: published),
    ) as Map<String, dynamic>,
  );

  Future<Paginated<FormSubmission>> submissions(
    String formId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final data = await api.getJson(
      '/api/form/$formId/submissions',
      query: {'page': '$page', 'pageSize': '$pageSize'},
    ) as Map<String, dynamic>;
    return Paginated(
      items: (data['items'] as List)
          .map((e) => FormSubmission.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: page,
      total: (data['total'] as num).toInt(),
      hasMore: page < (data['totalPages'] as num).toInt(),
    );
  }

  Future<void> deleteSubmission(String formId, String submissionId) =>
      api.delete('/api/form/$formId/submissions/$submissionId');

  // --- helpers ------------------------------------------------------------
  String imageUrl(String id) => api.fileUrl(id);

  http.MultipartFile _file(String field, UploadImage image) {
    final file = File(image.path);
    return http.MultipartFile(
      field,
      file.openRead(),
      file.lengthSync(),
      filename: image.filename,
      contentType: _contentType(image.filename),
    );
  }
}

MediaType _contentType(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.png')) return MediaType('image', 'png');
  if (lower.endsWith('.webp')) return MediaType('image', 'webp');
  if (lower.endsWith('.gif')) return MediaType('image', 'gif');
  return MediaType('image', 'jpeg');
}
