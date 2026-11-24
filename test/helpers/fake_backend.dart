import 'dart:convert';

import 'package:classicum_admin/app/dependencies.dart';
import 'package:classicum_admin/core/network/api_client.dart';
import 'package:classicum_admin/core/network/token_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

typedef Handler = http.Response Function(http.Request request);

/// In-memory stand-in for the Classicum website API.
class FakeBackend {
  FakeBackend({bool signedIn = true})
    : tokens = MemoryTokenStore(
        signedIn
            ? const AuthTokens(
                accessToken: 'access-1',
                refreshToken: 'refresh-1',
              )
            : null,
      ) {
    client = MockClient((request) async {
      requests.add(request);
      final key = '${request.method} ${request.url.path}';
      final handler = routes[key];
      if (handler == null) {
        return http.Response(jsonEncode({'error': 'no route $key'}), 404);
      }
      return handler(request);
    });
    api = ApiClient(
      baseUrl: 'https://example.test',
      tokens: tokens,
      httpClient: client,
    );
    deps = AppDependencies(api);
  }

  final MemoryTokenStore tokens;
  final Map<String, Handler> routes = {};
  final List<http.Request> requests = [];
  late final MockClient client;
  late final ApiClient api;
  late final AppDependencies deps;

  void json(String route, Object? body, {int status = 200}) {
    routes[route] = (_) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );
  }

  Iterable<http.Request> called(String route) =>
      requests.where((r) => '${r.method} ${r.url.path}' == route);
}

Map<String, dynamic> eventJson(
  String id,
  String titolo,
  DateTime when, {
  String luogo = 'Real Collegio',
}) => {
  'id': id,
  'titolo': titolo,
  'descrizione': 'Descrizione',
  'data': when.toUtc().toIso8601String(),
  'luogo': luogo,
  'imageId': null,
};

Map<String, dynamic> newsJson(String id, String title) => {
  'id': id,
  'title': title,
  'content': '<p>Testo di $title</p>',
  'createdAt': '2026-03-01T10:00:00.000Z',
  'newsImages': [
    {'id': 'ni-$id', 'fileId': 'file-$id', 'isMain': true, 'order': 0},
  ],
};
