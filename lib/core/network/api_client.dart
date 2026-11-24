import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:classicum_admin/core/network/token_store.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// Thin HTTP client for the Classicum website API.
///
/// Sends the access token as `Authorization: Bearer`, and transparently
/// refreshes it (once) when the server answers 401.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.tokens,
    http.Client? httpClient,
    this.onSessionExpired,
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final TokenStore tokens;
  final http.Client _http;

  /// Called when the refresh token is no longer valid.
  void Function()? onSessionExpired;

  Future<bool>? _refreshing;

  Uri uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse(baseUrl);
    return base.replace(
      path: path,
      queryParameters: query == null || query.isEmpty ? null : query,
    );
  }

  /// Public URL of an uploaded file (image).
  String fileUrl(String id) => uri('/api/storage/$id').toString();

  Future<dynamic> getJson(String path, {Map<String, String>? query}) async {
    final res = await _send(() async => http.Request('GET', uri(path, query)));
    return _decode(res);
  }

  Future<dynamic> sendJson(String method, String path, Object? body) async {
    final res = await _send(() async {
      final req = http.Request(method, uri(path));
      req.headers['Content-Type'] = 'application/json';
      req.body = jsonEncode(body);
      return req;
    });
    return _decode(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await _send(() async => http.Request('DELETE', uri(path)));
    return _decode(res);
  }

  /// Multipart request. [build] is called again if the request is retried
  /// after a token refresh, since a multipart request can't be re-sent.
  Future<dynamic> multipart(
    String method,
    String path, {
    required Map<String, String> fields,
    List<http.MultipartFile> Function()? files,
  }) async {
    final res = await _send(() async {
      final req = http.MultipartRequest(method, uri(path));
      req.fields.addAll(fields);
      if (files != null) req.files.addAll(files());
      return req;
    });
    return _decode(res);
  }

  /// Logs in and stores the tokens. Returns the user JSON.
  Future<Map<String, dynamic>> login(String email, String password) async {
    final req = http.Request('POST', uri('/api/auth/login'))
      ..headers.addAll({
        'Content-Type': 'application/json',
        'X-Client': 'mobile',
      })
      ..body = jsonEncode({'email': email, 'password': password});
    final res = await http.Response.fromStream(await _http.send(req));
    final data = _decode(res) as Map<String, dynamic>;
    final access = data['accessToken'];
    final refresh = data['refreshToken'];
    if (access is! String || refresh is! String) {
      throw ApiException(
        500,
        'Il server non ha restituito i token. Aggiorna il sito.',
      );
    }
    await tokens.write(AuthTokens(accessToken: access, refreshToken: refresh));
    return data['user'] as Map<String, dynamic>;
  }

  Future<void> logout() async {
    final stored = await tokens.read();
    if (stored != null) {
      try {
        final req = http.Request('POST', uri('/api/auth/logout'))
          ..headers.addAll({
            'Content-Type': 'application/json',
            'X-Client': 'mobile',
          })
          ..body = jsonEncode({'refreshToken': stored.refreshToken});
        await _http.send(req).timeout(const Duration(seconds: 5));
      } catch (_) {
        // Best effort: the local session is cleared regardless.
      }
    }
    await tokens.clear();
  }

  Future<bool> hasSession() async => (await tokens.read()) != null;

  Future<http.Response> _send(
    Future<http.BaseRequest> Function() build, {
    bool retry = true,
  }) async {
    final req = await build();
    final stored = await tokens.read();
    if (stored != null) {
      req.headers['Authorization'] = 'Bearer ${stored.accessToken}';
    }
    final http.Response res;
    try {
      res = await http.Response.fromStream(await _http.send(req));
    } on http.ClientException catch (e) {
      throw ApiException(0, 'Connessione non riuscita: ${e.message}');
    } on TimeoutException {
      throw ApiException(0, 'Il server non risponde');
    }
    if (res.statusCode == 401 && retry && stored != null) {
      if (await _refresh(stored.refreshToken)) {
        return _send(build, retry: false);
      }
      await tokens.clear();
      onSessionExpired?.call();
    }
    return res;
  }

  Future<bool> _refresh(String refreshToken) {
    // Single flight: concurrent 401s share one refresh call.
    return _refreshing ??= _doRefresh(refreshToken).whenComplete(() {
      _refreshing = null;
    });
  }

  Future<bool> _doRefresh(String refreshToken) async {
    try {
      final req = http.Request('POST', uri('/api/auth/refresh'))
        ..headers.addAll({
          'Content-Type': 'application/json',
          'X-Client': 'mobile',
        })
        ..body = jsonEncode({'refreshToken': refreshToken});
      final res = await http.Response.fromStream(await _http.send(req));
      if (res.statusCode != 200) return false;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final access = data['accessToken'];
      final refresh = data['refreshToken'];
      if (access is! String || refresh is! String) return false;
      await tokens.write(
        AuthTokens(accessToken: access, refreshToken: refresh),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  dynamic _decode(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      try {
        return jsonDecode(utf8.decode(res.bodyBytes));
      } on FormatException {
        return res.body; // some endpoints reply with plain text
      }
    }
    var message = 'Errore ${res.statusCode}';
    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (body is Map && body['error'] is String) {
        message = body['error'] as String;
      }
    } on FormatException {
      if (res.body.isNotEmpty && res.body.length < 200) message = res.body;
    }
    throw ApiException(res.statusCode, message);
  }
}
