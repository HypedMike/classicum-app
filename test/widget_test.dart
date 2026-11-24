import 'dart:convert';

import 'package:classicum_admin/app.dart';
import 'package:classicum_admin/state/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/fake_backend.dart';

Future<void> pumpApp(WidgetTester tester, FakeBackend b) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final auth = AuthController(b.repository);
  await tester.pumpWidget(ClassicumApp(repository: b.repository, auth: auth));
  await auth.restore();
  await tester.pumpAndSettle();
}

FakeBackend signedInBackend() {
  final b = FakeBackend();
  b.json('GET /api/auth/me', {
    'user': {'id': 'u1', 'email': 'anna@classicum.it'},
  });
  final future = DateTime.now().add(const Duration(days: 10));
  final past = DateTime.now().subtract(const Duration(days: 10));
  b.json('GET /api/eventi', [
    eventJson('e1', 'Stati Generali', future),
    eventJson('e2', 'Serata passata', past),
  ]);
  b.json('GET /api/news', {
    'data': [newsJson('n1', 'Cerchio Verde')],
    'total': 1,
    'page': 1,
    'limit': 3,
  });
  b.json('GET /api/contact', {
    'items': [
      {
        'id': 'm1',
        'name': 'Marco Rossi',
        'email': 'marco@example.it',
        'message': 'Vorrei prenotare una sala',
        'createdAt': '2026-02-01T10:00:00Z',
      },
    ],
    'page': 1,
    'pageSize': 20,
    'total': 1,
    'totalPages': 1,
  });
  b.json('GET /api/form', {
    'items': [
      {
        'id': 'f1',
        'name': 'Redazione Simulata',
        'description': 'Iscrizioni',
        'published': true,
        'fields': [
          {'key': 'nome', 'type': 'string', 'value': ''},
          {'key': 'maggiorenne', 'type': 'boolean', 'value': false},
        ],
      },
    ],
    'page': 1,
    'pageSize': 20,
    'total': 1,
    'totalPages': 1,
  });
  b.json('GET /api/form/f1/submissions', {
    'items': [
      {
        'id': 's1',
        'formId': 'f1',
        'createdAt': '2026-02-02T10:00:00Z',
        'answers': [
          {'key': 'nome', 'value': 'Giulia Bianchi'},
          {'key': 'maggiorenne', 'value': true},
        ],
      },
    ],
    'page': 1,
    'pageSize': 20,
    'total': 1,
    'totalPages': 1,
  });
  return b;
}

void main() {
  setUpAll(() => initializeDateFormatting('it'));

  group('login', () {
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
  });

  group('signed in', () {
    testWidgets('home shows the next upcoming event and latest news', (
      tester,
    ) async {
      await pumpApp(tester, signedInBackend());
      expect(find.text('CIAO ANNA'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('next-event-card')),
          matching: find.text('Stati Generali'),
        ),
        findsOneWidget,
      );
      expect(find.text('Cerchio Verde', skipOffstage: false), findsOneWidget);
    });

    testWidgets('agenda hides past events until filtered', (tester) async {
      await pumpApp(tester, signedInBackend());
      await tester.tap(find.text('Agenda').last);
      await tester.pumpAndSettle();
      expect(find.text('Serata passata'), findsNothing);
      await tester.tap(find.text('Passati'));
      await tester.pumpAndSettle();
      expect(find.text('Serata passata'), findsOneWidget);
      expect(find.text('Stati Generali'), findsNothing);
    });

    testWidgets('deleting an event asks for confirmation then calls the API', (
      tester,
    ) async {
      final b = signedInBackend();
      b.routes['DELETE /api/eventi/e1'] = (_) => http.Response('ok', 200);
      await pumpApp(tester, b);
      await tester.tap(find.text('Agenda').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Elimina Stati Generali'));
      await tester.pumpAndSettle();
      expect(b.called('DELETE /api/eventi/e1'), isEmpty);
      await tester.tap(find.text('Elimina'));
      await tester.pumpAndSettle();
      expect(b.called('DELETE /api/eventi/e1'), hasLength(1));
    });

    testWidgets('cancelling the confirmation keeps the event', (tester) async {
      final b = signedInBackend();
      await pumpApp(tester, b);
      await tester.tap(find.text('Agenda').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Elimina Stati Generali'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();
      expect(b.called('DELETE /api/eventi/e1'), isEmpty);
    });

    testWidgets('new event form requires its fields', (tester) async {
      final b = signedInBackend();
      await pumpApp(tester, b);
      await tester.tap(find.text('Agenda').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-event')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('event-save')));
      await tester.pump();
      expect(find.text('Campo obbligatorio'), findsWidgets);
      expect(find.text('Scegli data e ora'), findsOneWidget);
      expect(b.called('POST /api/eventi'), isEmpty);
    });

    testWidgets('messages list shows contact requests', (tester) async {
      await pumpApp(tester, signedInBackend());
      await tester.tap(find.text('Messaggi').last);
      await tester.pumpAndSettle();
      expect(find.text('Marco Rossi'), findsOneWidget);
      expect(find.text('Vorrei prenotare una sala'), findsOneWidget);
    });

    testWidgets('forms list opens submissions with readable answers', (
      tester,
    ) async {
      await pumpApp(tester, signedInBackend());
      await tester.tap(find.text('Moduli').last);
      await tester.pumpAndSettle();
      expect(find.text('Redazione Simulata'), findsOneWidget);
      expect(find.text('Pubblico'), findsOneWidget);
      await tester.tap(find.text('Redazione Simulata'));
      await tester.pumpAndSettle();
      expect(find.text('Giulia Bianchi'), findsOneWidget);
      expect(find.text('Sì'), findsOneWidget);
    });

    testWidgets('logging out returns to the login screen', (tester) async {
      final b = signedInBackend();
      b.json('POST /api/auth/logout', {'ok': true});
      await pumpApp(tester, b);
      await tester.tap(find.text('Profilo').last);
      await tester.pumpAndSettle();
      expect(find.text('anna@classicum.it'), findsOneWidget);
      await tester.tap(find.byKey(const Key('logout')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('login-submit')), findsOneWidget);
    });

    testWidgets('an expired session sends the user back to login', (
      tester,
    ) async {
      final b = signedInBackend();
      await pumpApp(tester, b);
      b.json('GET /api/eventi', {'error': 'x'}, status: 401);
      b.json('POST /api/auth/refresh', {'error': 'x'}, status: 401);
      await tester.tap(find.text('Agenda').last);
      await tester.pump();
      await tester.runAsync(() async {
        try {
          await b.repository.events();
        } catch (_) {}
      });
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('login-submit')), findsOneWidget);
    });
  });
}
