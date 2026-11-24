import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../helpers/fake_backend.dart';

void main() {
  test('creating an event posts multipart fields', () async {
    final b = FakeBackend();
    b.routes['POST /api/eventi'] = (_) => http.Response('{}', 201);
    await b.deps.events.createEvent(
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
}
