import 'dart:convert';

import 'package:classicum_admin/data/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'helpers/fake_backend.dart';

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
    final page = await b.repository.news(limit: 2);
    expect(page.items.map((n) => n.title), ['Uno', 'Due']);
    expect(page.hasMore, isTrue);
    expect(page.total, 3);
  });

  test('updating news keeps the existing images', () async {
    final b = FakeBackend();
    b.routes['PUT /api/news/1'] = (_) => http.Response('{}', 200);
    final item = NewsItem.fromJson(newsJson('1', 'Uno'));
    await b.repository.updateNews(item, title: 'Nuovo', content: '<p>x</p>');
    final req = b.called('PUT /api/news/1').single;
    final body = utf8.decode(req.bodyBytes);
    expect(req.headers['content-type'], startsWith('multipart/form-data'));
    expect(body, contains('name="title"'));
    expect(body, contains('Nuovo'));
    expect(body, contains('"fileId":"file-1"'));
    expect(body, contains('"isMain":true'));
  });

  test('creating a comunicato sends JSON with a UTC date', () async {
    final b = FakeBackend();
    b.routes['POST /api/comunitcati'] = (_) => http.Response('{}', 201);
    await b.repository.createComunicato(
      title: 'T',
      description: 'D',
      date: DateTime.utc(2026, 3, 4, 5),
    );
    final req = b.called('POST /api/comunitcati').single;
    expect(jsonDecode(req.body), {
      'title': 'T',
      'description': 'D',
      'date': '2026-03-04T05:00:00.000Z',
    });
  });

  test('creating an event posts multipart fields', () async {
    final b = FakeBackend();
    b.routes['POST /api/eventi'] = (_) => http.Response('{}', 201);
    await b.repository.createEvent(
      titolo: 'Festa',
      descrizione: 'Desc',
      data: DateTime.utc(2026, 7, 1, 18),
      luogo: 'Lucca',
    );
    final body = utf8.decode(b.called('POST /api/eventi').single.bodyBytes);
    for (final f in ['titolo', 'descrizione', 'data', 'luogo']) {
      expect(body, contains('name="$f"'));
    }
    expect(body, contains('2026-07-01T18:00:00.000Z'));
    expect(body, isNot(contains('name="image"')));
  });

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
    final res = await b.repository.messages(search: 'anna');
    expect(res.items.single.name, 'Anna');
    expect(res.hasMore, isFalse);
  });

  test('publishing a form PUTs the whole definition', () async {
    final b = FakeBackend();
    b.routes['PUT /api/form/f1'] = (req) {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response(jsonEncode({'id': 'f1', ...body}), 200);
    };
    final form = FormDefinition.fromJson({
      'id': 'f1',
      'name': 'Iscrizione',
      'description': 'd',
      'published': false,
      'fields': [
        {'key': 'nome', 'type': 'string', 'value': ''},
      ],
    });
    final updated = await b.repository.setFormPublished(form, true);
    expect(updated.published, isTrue);
    expect(updated.fields.single.key, 'nome');
  });

  test(
    'currentUser is null without a session or with an expired one',
    () async {
      final none = FakeBackend(signedIn: false);
      expect(await none.repository.currentUser(), isNull);

      final expired = FakeBackend();
      expired.json('GET /api/auth/me', {'error': 'Unauthorized'}, status: 401);
      expired.json('POST /api/auth/refresh', {'error': 'x'}, status: 401);
      expect(await expired.repository.currentUser(), isNull);
    },
  );

  test('currentUser parses the session user', () async {
    final b = FakeBackend();
    b.json('GET /api/auth/me', {
      'user': {'id': 'u', 'email': 'a@b.it'},
    });
    expect((await b.repository.currentUser())?.email, 'a@b.it');
  });
}
