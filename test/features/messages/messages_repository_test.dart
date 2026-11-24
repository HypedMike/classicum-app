import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../helpers/fake_backend.dart';

void main() {
  test('messages pass the search term and paging', () async {
    final b = FakeBackend();
    b.routes['GET /api/contact'] = (req) {
      expect(req.url.queryParameters['search'], 'anna');
      return http.Response(
        jsonEncode({
          'items': [
            {
              'id': 'm1',
              'name': 'Anna',
              'email': 'a@b.it',
              'message': 'Ciao',
              'createdAt': '2026-01-01T00:00:00Z',
            },
          ],
          'page': 1,
          'pageSize': 20,
          'total': 1,
          'totalPages': 1,
        }),
        200,
      );
    };
    final res = await b.deps.messages.messages(search: 'anna');
    expect(res.items.single.name, 'Anna');
    expect(res.hasMore, isFalse);
  });
}
