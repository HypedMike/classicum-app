import 'package:classicum_admin/app/app.dart';
import 'package:classicum_admin/features/auth/presentation/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'fake_backend.dart';

Future<void> pumpApp(WidgetTester tester, FakeBackend b) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final auth = AuthController(b.deps.auth);
  await tester.pumpWidget(
    ClassicumApp(deps: b.deps, auth: auth, minSplash: Duration.zero),
  );
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
