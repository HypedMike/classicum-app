import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../helpers/fake_backend.dart';

void main() {
  test('creating a comunicato sends JSON with a UTC date', () async {
    final b = FakeBackend();
    b.routes['POST /api/comunitcati'] = (_) => http.Response('{}', 201);
    await b.deps.comunicati.createComunicato(
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
}
