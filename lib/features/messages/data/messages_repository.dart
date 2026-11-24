import 'package:classicum_admin/core/network/api_client.dart';
import 'package:classicum_admin/core/pagination.dart';
import 'package:classicum_admin/features/messages/data/contact_message.dart';

class MessagesRepository {
  MessagesRepository(this.api);

  final ApiClient api;

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
}
