import 'dart:convert';

import 'package:classicum_admin/core/network/api_client.dart';
import 'package:classicum_admin/core/network/token_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../helpers/fake_backend.dart';

void main() {
  test('login asks for tokens and stores them', () async {
    final b = FakeBackend(signedIn: false);
    b.routes['POST /api/auth/login'] = (req) {
      expect(req.headers['X-Client'], 'mobile');
      expect(jsonDecode(req.body), {'email': 'a@b.it', 'password': 'pw'});
      return http.Response(
        jsonEncode({
          'user': {'id': 'u1', 'email': 'a@b.it'},
          'accessToken': 'A',
          'refreshToken': 'R',
        }),
        200,
      );
    };
    final user = await b.api.login('a@b.it', 'pw');
    expect(user['id'], 'u1');
    final stored = await b.tokens.read();
    expect(stored?.accessToken, 'A');
    expect(stored?.refreshToken, 'R');
  });

  test('login fails clearly when the server sends no tokens', () async {
    final b = FakeBackend(signedIn: false);
    b.json('POST /api/auth/login', {
      'user': {'id': 'u1', 'email': 'a@b.it'},
    });
    expect(b.api.login('a@b.it', 'pw'), throwsA(isA<ApiException>()));
  });

  test('wrong credentials surface the server message', () async {
    final b = FakeBackend(signedIn: false);
    b.json('POST /api/auth/login', {
      'error': 'Invalid credentials',
    }, status: 401);
    await expectLater(
      b.api.login('a@b.it', 'x'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.message, 'message', 'Invalid credentials')
            .having((e) => e.statusCode, 'status', 401),
      ),
    );
  });

  test('requests carry the bearer token', () async {
    final b = FakeBackend();
    b.json('GET /api/eventi', []);
    await b.api.getJson('/api/eventi');
    expect(b.requests.single.headers['Authorization'], 'Bearer access-1');
  });

  test('a 401 triggers one refresh and the request is retried', () async {
    final b = FakeBackend();
    var calls = 0;
    b.routes['GET /api/eventi'] = (req) {
      calls++;
      if (req.headers['Authorization'] == 'Bearer access-1') {
        return http.Response('Unauthorized', 401);
      }
      expect(req.headers['Authorization'], 'Bearer access-2');
      return http.Response('[]', 200);
    };
    b.routes['POST /api/auth/refresh'] = (req) {
      expect(jsonDecode(req.body), {'refreshToken': 'refresh-1'});
      return http.Response(
        jsonEncode({
          'ok': true,
          'accessToken': 'access-2',
          'refreshToken': 'refresh-2',
        }),
        200,
      );
    };
    expect(await b.api.getJson('/api/eventi'), isEmpty);
    expect(calls, 2);
    expect((await b.tokens.read())?.refreshToken, 'refresh-2');
  });

  test('concurrent 401s share a single refresh', () async {
    final b = FakeBackend();
    b.routes['GET /api/eventi'] = (req) =>
        req.headers['Authorization'] == 'Bearer access-2'
        ? http.Response('[]', 200)
        : http.Response('', 401);
    b.routes['POST /api/auth/refresh'] = (_) => http.Response(
      jsonEncode({
        'ok': true,
        'accessToken': 'access-2',
        'refreshToken': 'refresh-2',
      }),
      200,
    );
    await Future.wait([
      b.api.getJson('/api/eventi'),
      b.api.getJson('/api/eventi'),
    ]);
    expect(b.called('POST /api/auth/refresh'), hasLength(1));
  });

  test('a failed refresh clears the session and notifies', () async {
    final b = FakeBackend();
    var expired = false;
    b.api.onSessionExpired = () => expired = true;
    b.json('GET /api/eventi', {'error': 'no'}, status: 401);
    b.json('POST /api/auth/refresh', {'error': 'no'}, status: 401);
    await expectLater(
      b.api.getJson('/api/eventi'),
      throwsA(isA<ApiException>().having((e) => e.isUnauthorized, '401', true)),
    );
    expect(expired, isTrue);
    expect(await b.tokens.read(), isNull);
  });

  test('plain-text error bodies become the message', () async {
    final b = FakeBackend();
    b.routes['DELETE /api/eventi/1'] = (_) =>
        http.Response('Evento not found', 404);
    await expectLater(
      b.api.delete('/api/eventi/1'),
      throwsA(
        isA<ApiException>().having((e) => e.message, 'm', 'Evento not found'),
      ),
    );
  });

  test('logout revokes the refresh token and clears storage', () async {
    final b = FakeBackend();
    b.json('POST /api/auth/logout', {'ok': true});
    await b.api.logout();
    final req = b.called('POST /api/auth/logout').single;
    expect(jsonDecode(req.body), {'refreshToken': 'refresh-1'});
    expect(await b.tokens.read(), isNull);
  });

  test('logout clears local tokens even when offline', () async {
    final b = FakeBackend();
    b.routes['POST /api/auth/logout'] = (_) =>
        throw http.ClientException('offline');
    await b.api.logout();
    expect(await b.tokens.read(), isNull);
  });

  test('network failures become ApiException with status 0', () async {
    final b = FakeBackend();
    b.routes['GET /api/eventi'] = (_) => throw http.ClientException('down');
    await expectLater(
      b.api.getJson('/api/eventi'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 's', 0)),
    );
  });

  test('fileUrl points at the storage endpoint', () {
    final b = FakeBackend();
    expect(b.api.fileUrl('abc'), 'https://example.test/api/storage/abc');
  });

  test('MemoryTokenStore round-trips', () async {
    final s = MemoryTokenStore();
    expect(await s.read(), isNull);
    await s.write(const AuthTokens(accessToken: 'a', refreshToken: 'r'));
    expect((await s.read())?.accessToken, 'a');
    await s.clear();
    expect(await s.read(), isNull);
  });
}
