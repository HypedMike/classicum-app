import 'package:classicum_admin/core/network/api_client.dart';
import 'package:classicum_admin/core/pagination.dart';
import 'package:classicum_admin/features/forms/data/form_models.dart';

class FormsRepository {
  FormsRepository(this.api);

  final ApiClient api;

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
}
