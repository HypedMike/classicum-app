import 'package:classicum_admin/core/network/api_client.dart';
import 'package:classicum_admin/features/comunicati/data/comunicato.dart';

class ComunicatiRepository {
  ComunicatiRepository(this.api);

  final ApiClient api;

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
}
