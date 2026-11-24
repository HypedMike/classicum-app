import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_backend.dart';

void main() {
  test(
    'currentUser is null without a session or with an expired one',
    () async {
      final none = FakeBackend(signedIn: false);
      expect(await none.deps.auth.currentUser(), isNull);

      final expired = FakeBackend();
      expired.json('GET /api/auth/me', {'error': 'Unauthorized'}, status: 401);
      expired.json('POST /api/auth/refresh', {'error': 'x'}, status: 401);
      expect(await expired.deps.auth.currentUser(), isNull);
    },
  );

  test('currentUser parses the session user', () async {
    final b = FakeBackend();
    b.json('GET /api/auth/me', {
      'user': {'id': 'u', 'email': 'a@b.it'},
    });
    expect((await b.deps.auth.currentUser())?.email, 'a@b.it');
  });
}
