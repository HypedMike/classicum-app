import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

Map<String, dynamic> message(int i) => {
  'id': 'm$i',
  'name': 'Persona $i',
  'email': 'p$i@example.it',
  'message': 'Messaggio $i',
  'createdAt': '2026-02-01T10:00:00Z',
};

void main() {
  setUpAll(() => initializeDateFormatting('it'));

  testWidgets('searching reloads with the search term', (tester) async {
    final b = signedInBackend();
    await pumpApp(tester, b);
    await tester.tap(find.text('Messaggi').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('messages-search')), 'marco');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(
      b.called('GET /api/contact').last.url.queryParameters['search'],
      'marco',
    );
  });

  testWidgets('deleting a message confirms, deletes and reloads', (
    tester,
  ) async {
    final b = signedInBackend();
    b.routes['DELETE /api/contact/m1'] = (_) => http.Response('ok', 200);
    await pumpApp(tester, b);
    await tester.tap(find.text('Messaggi').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Elimina messaggio di Marco Rossi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();
    expect(b.called('DELETE /api/contact/m1'), hasLength(1));
    expect(b.called('GET /api/contact').length, 2);
  });

  testWidgets('an empty inbox says so', (tester) async {
    final b = signedInBackend();
    b.json('GET /api/contact', {
      'items': [],
      'page': 1,
      'pageSize': 20,
      'total': 0,
      'totalPages': 1,
    });
    await pumpApp(tester, b);
    await tester.tap(find.text('Messaggi').last);
    await tester.pumpAndSettle();
    expect(find.text('Nessun messaggio.'), findsOneWidget);
  });

  testWidgets('more pages are loaded on demand', (tester) async {
    final b = signedInBackend();
    b.routes['GET /api/contact'] = (req) {
      final page = int.parse(req.url.queryParameters['page']!);
      return http.Response(
        jsonEncode({
          'items': [message(page)],
          'page': page,
          'pageSize': 20,
          'total': 2,
          'totalPages': 2,
        }),
        200,
      );
    };
    await pumpApp(tester, b);
    await tester.tap(find.text('Messaggi').last);
    await tester.pumpAndSettle();
    expect(find.text('Persona 1'), findsOneWidget);
    await tester.ensureVisible(find.text('Carica altri'));
    await tester.tap(find.text('Carica altri'));
    await tester.pumpAndSettle();
    expect(find.text('Persona 2', skipOffstage: false), findsOneWidget);
    expect(find.text('Carica altri'), findsNothing);
  });

  testWidgets('a load error is shown with retry', (tester) async {
    final b = signedInBackend();
    b.json('GET /api/contact', {'error': 'Boom'}, status: 500);
    await pumpApp(tester, b);
    await tester.tap(find.text('Messaggi').last);
    await tester.pumpAndSettle();
    expect(find.text('Boom'), findsOneWidget);
    expect(find.text('Riprova'), findsOneWidget);
  });
}
