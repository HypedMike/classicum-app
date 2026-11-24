import 'dart:convert';

import 'package:classicum_admin/features/comunicati/data/comunicato.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/fake_backend.dart';
import '../../helpers/pump_app.dart';

Map<String, dynamic> comunicatoJson(String id, String title, String date) => {
  'id': id,
  'title': title,
  'description': 'Testo $title',
  'date': date,
};

FakeBackend backend() {
  final b = signedInBackend();
  b.json('GET /api/comunitcati', [
    comunicatoJson('c1', 'Vecchio comunicato', '2025-01-10T10:00:00.000Z'),
    comunicatoJson('c2', 'Ultimo comunicato', '2026-06-10T10:00:00.000Z'),
  ]);
  return b;
}

Future<void> openList(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(InkWell, 'Comunicati stampa'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('it'));

  test('Comunicato parses its JSON', () {
    final c = Comunicato.fromJson(
      comunicatoJson('c1', 'T', '2026-03-04T05:00:00.000Z'),
    );
    expect(c.title, 'T');
    expect(c.description, 'Testo T');
    expect(c.date.toUtc(), DateTime.utc(2026, 3, 4, 5));
  });

  test('repository updates with PUT and a UTC date', () async {
    final b = FakeBackend();
    b.routes['PUT /api/comunitcati/c1'] = (_) => http.Response('{}', 200);
    await b.deps.comunicati.updateComunicato(
      'c1',
      title: 'T',
      description: 'D',
      date: DateTime.utc(2026, 1, 2),
    );
    final req = b.called('PUT /api/comunitcati/c1').single;
    expect(jsonDecode(req.body)['date'], '2026-01-02T00:00:00.000Z');
  });

  test('repository deletes by id', () async {
    final b = FakeBackend();
    b.routes['DELETE /api/comunitcati/c1'] = (_) =>
        http.Response('Comunicato deleted successfully', 200);
    await b.deps.comunicati.deleteComunicato('c1');
    expect(b.called('DELETE /api/comunitcati/c1'), hasLength(1));
  });

  testWidgets('list shows the most recent comunicato first', (tester) async {
    await pumpApp(tester, backend());
    await openList(tester);
    final newer = tester.getTopLeft(find.text('Ultimo comunicato')).dy;
    final older = tester.getTopLeft(find.text('Vecchio comunicato')).dy;
    expect(newer, lessThan(older));
  });

  testWidgets('an empty list says so', (tester) async {
    final b = backend();
    b.json('GET /api/comunitcati', []);
    await pumpApp(tester, b);
    await openList(tester);
    expect(find.text('Nessun comunicato.'), findsOneWidget);
  });

  testWidgets('deleting asks for confirmation first', (tester) async {
    final b = backend();
    b.routes['DELETE /api/comunitcati/c2'] = (_) => http.Response('ok', 200);
    await pumpApp(tester, b);
    await openList(tester);
    await tester.tap(find.byTooltip('Elimina Ultimo comunicato'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(b.called('DELETE /api/comunitcati/c2'), isEmpty);
    await tester.tap(find.byTooltip('Elimina Ultimo comunicato'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();
    expect(b.called('DELETE /api/comunitcati/c2'), hasLength(1));
  });

  testWidgets('creating validates then posts JSON', (tester) async {
    final b = backend();
    b.routes['POST /api/comunitcati'] = (_) => http.Response('{}', 201);
    await pumpApp(tester, b);
    await openList(tester);
    await tester.tap(find.byTooltip('Nuovo comunicato'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('comunicato-save')));
    await tester.pump();
    expect(find.text('Campo obbligatorio'), findsNWidgets(2));
    expect(b.called('POST /api/comunitcati'), isEmpty);

    await tester.enterText(find.byKey(const Key('comunicato-title')), 'Titolo');
    await tester.enterText(
      find.byKey(const Key('comunicato-description')),
      'Testo',
    );
    await tester.tap(find.byKey(const Key('comunicato-save')));
    await tester.pumpAndSettle();
    final body = jsonDecode(b.called('POST /api/comunitcati').single.body);
    expect(body['title'], 'Titolo');
    expect(body['description'], 'Testo');
    expect(find.byKey(const Key('comunicato-save')), findsNothing);
  });

  testWidgets('editing prefills the form and sends a PUT', (tester) async {
    final b = backend();
    b.routes['PUT /api/comunitcati/c2'] = (_) => http.Response('{}', 200);
    await pumpApp(tester, b);
    await openList(tester);
    await tester.tap(find.text('Ultimo comunicato'));
    await tester.pumpAndSettle();
    expect(find.text('Modifica comunicato'), findsOneWidget);
    expect(find.text('Testo Ultimo comunicato'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('comunicato-title')),
      'Titolo nuovo',
    );
    await tester.tap(find.byKey(const Key('comunicato-save')));
    await tester.pumpAndSettle();
    final body = jsonDecode(b.called('PUT /api/comunitcati/c2').single.body);
    expect(body['title'], 'Titolo nuovo');
  });
}
