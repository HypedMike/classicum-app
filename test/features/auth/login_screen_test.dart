import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/fake_backend.dart';
import '../../helpers/pump_app.dart';

void main() {
  setUpAll(() => initializeDateFormatting('it'));
  testWidgets('signed-out users see the login screen', (tester) async {
    await pumpApp(tester, FakeBackend(signedIn: false));
    expect(find.byKey(const Key('login-submit')), findsOneWidget);
  });

  testWidgets('empty fields are validated before calling the API', (
    tester,
  ) async {
    final b = FakeBackend(signedIn: false);
    await pumpApp(tester, b);
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();
    expect(find.text('Inserisci un indirizzo email valido'), findsOneWidget);
    expect(find.text('Inserisci la password'), findsOneWidget);
    expect(b.requests, isEmpty);
  });

  testWidgets('wrong credentials show the server error', (tester) async {
    final b = FakeBackend(signedIn: false);
    b.json('POST /api/auth/login', {
      'error': 'Invalid credentials',
    }, status: 401);
    await pumpApp(tester, b);
    await tester.enterText(find.byKey(const Key('login-email')), 'a@b.it');
    await tester.enterText(find.byKey(const Key('login-password')), 'bad');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Invalid credentials'), findsOneWidget);
  });

  testWidgets('a successful login opens the app', (tester) async {
    final b = signedInBackend();
    await b.tokens.clear();
    b.routes['POST /api/auth/login'] = (_) => http.Response(
      jsonEncode({
        'user': {'id': 'u1', 'email': 'anna@classicum.it'},
        'accessToken': 'A',
        'refreshToken': 'R',
      }),
      200,
    );
    await pumpApp(tester, b);
    await tester.enterText(
      find.byKey(const Key('login-email')),
      'anna@classicum.it',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'password1',
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Gestisci'), findsOneWidget);
  });
}
