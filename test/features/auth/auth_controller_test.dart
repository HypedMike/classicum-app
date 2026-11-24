import 'package:classicum_admin/features/auth/presentation/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../helpers/fake_backend.dart';

void main() {
  test('starts unknown, then signed out without a session', () async {
    final b = FakeBackend(signedIn: false);
    final auth = AuthController(b.deps.auth);
    expect(auth.status, AuthStatus.unknown);
    await auth.restore();
    expect(auth.status, AuthStatus.signedOut);
    expect(auth.user, isNull);
  });

  test('restore signs in with a valid stored session', () async {
    final b = FakeBackend();
    b.json('GET /api/auth/me', {
      'user': {'id': 'u1', 'email': 'a@b.it'},
    });
    final auth = AuthController(b.deps.auth);
    await auth.restore();
    expect(auth.status, AuthStatus.signedIn);
    expect(auth.user?.email, 'a@b.it');
  });

  test('restore signs out when the stored session is rejected', () async {
    final b = FakeBackend();
    b.json('GET /api/auth/me', {'error': 'x'}, status: 401);
    b.json('POST /api/auth/refresh', {'error': 'x'}, status: 401);
    final auth = AuthController(b.deps.auth);
    await auth.restore();
    expect(auth.status, AuthStatus.signedOut);
  });

  test('restore while offline does not crash and stays signed out', () async {
    final b = FakeBackend();
    b.routes['GET /api/auth/me'] = (_) => throw http.ClientException('offline');
    final auth = AuthController(b.deps.auth);
    await auth.restore();
    expect(auth.status, AuthStatus.signedOut);
    // The stored tokens are kept so the next launch can retry.
    expect(await b.tokens.read(), isNotNull);
  });

  test('login and logout notify listeners and change status', () async {
    final b = FakeBackend(signedIn: false);
    b.json('POST /api/auth/login', {
      'user': {'id': 'u1', 'email': 'a@b.it'},
      'accessToken': 'A',
      'refreshToken': 'R',
    });
    b.json('POST /api/auth/logout', {'ok': true});
    final auth = AuthController(b.deps.auth);
    var notified = 0;
    auth.addListener(() => notified++);

    await auth.login('a@b.it', 'pw');
    expect(auth.status, AuthStatus.signedIn);
    await auth.logout();
    expect(auth.status, AuthStatus.signedOut);
    expect(auth.user, isNull);
    expect(await b.tokens.read(), isNull);
    expect(notified, 2);
  });

  test('a failed login leaves the controller signed out', () async {
    final b = FakeBackend(signedIn: false);
    b.json('POST /api/auth/login', {
      'error': 'Invalid credentials',
    }, status: 401);
    final auth = AuthController(b.deps.auth);
    await expectLater(auth.login('a@b.it', 'x'), throwsA(isA<Exception>()));
    expect(auth.status, isNot(AuthStatus.signedIn));
  });

  test('an expired session signs the user out', () async {
    final b = FakeBackend();
    b.json('GET /api/auth/me', {
      'user': {'id': 'u1', 'email': 'a@b.it'},
    });
    b.json('GET /api/eventi', {'error': 'x'}, status: 401);
    b.json('POST /api/auth/refresh', {'error': 'x'}, status: 401);
    final auth = AuthController(b.deps.auth);
    await auth.restore();
    expect(auth.status, AuthStatus.signedIn);
    try {
      await b.deps.events.events();
    } catch (_) {}
    expect(auth.status, AuthStatus.signedOut);
  });
}
