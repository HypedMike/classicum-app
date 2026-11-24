import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:classicum_admin/features/news/data/news_item.dart';

import '../../helpers/fake_backend.dart';

void main() {
  test('news pagination reports whether more pages exist', () async {
    final b = FakeBackend();
    b.routes['GET /api/news'] = (req) {
      expect(req.url.queryParameters, {'page': '1', 'limit': '2'});
      return http.Response(
        jsonEncode({
          'data': [newsJson('1', 'Uno'), newsJson('2', 'Due')],
          'total': 3,
          'page': 1,
          'limit': 2,
        }),
        200,
      );
    };
    final page = await b.deps.news.news(limit: 2);
    expect(page.items.map((n) => n.title), ['Uno', 'Due']);
    expect(page.hasMore, isTrue);
    expect(page.total, 3);
  });

  test('updating news keeps the existing images', () async {
    final b = FakeBackend();
    b.routes['PUT /api/news/1'] = (_) => http.Response('{}', 200);
    final item = NewsItem.fromJson(newsJson('1', 'Uno'));
    await b.deps.news.updateNews(item, title: 'Nuovo', content: '<p>x</p>');
    final req = b.called('PUT /api/news/1').single;
    final body = utf8.decode(req.bodyBytes);
    expect(req.headers['content-type'], startsWith('multipart/form-data'));
    expect(body, contains('name="title"'));
    expect(body, contains('Nuovo'));
    expect(body, contains('"fileId":"file-1"'));
    expect(body, contains('"isMain":true'));
  });
}
