import 'package:classicum_admin/core/network/api_client.dart';
import 'package:classicum_admin/core/network/uploads.dart';
import 'package:classicum_admin/features/agenda/data/evento.dart';

class EventsRepository {
  EventsRepository(this.api);

  final ApiClient api;

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
      files: image == null ? null : () => [multipartFile('image', image)],
    );
  }

  Future<void> deleteEvent(String id) => api.delete('/api/eventi/$id');
}
