import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

Future<void> openForm(WidgetTester tester) async {
  await tester.tap(find.text('Agenda').last);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('add-event')));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('it'));

  testWidgets('creating an event with date, time and fields posts it', (
    tester,
  ) async {
    final b = signedInBackend();
    b.routes['POST /api/eventi'] = (_) => http.Response('{}', 201);
    await pumpApp(tester, b);
    await openForm(tester);

    await tester.enterText(find.byKey(const Key('event-title')), 'Festa');
    await tester.enterText(find.byKey(const Key('event-place')), 'Lucca');
    await tester.enterText(
      find.byKey(const Key('event-description')),
      'Una festa',
    );
    await tester.tap(find.byKey(const Key('event-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK')); // date picker
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK')); // time picker
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('event-save')));
    await tester.pumpAndSettle();

    final body = utf8.decode(b.called('POST /api/eventi').single.bodyBytes);
    expect(body, contains('Festa'));
    expect(body, contains('Lucca'));
    expect(body, contains('name="data"'));
    expect(body, isNot(contains('name="image"')));
    // Back on the agenda, which reloaded.
    expect(find.byKey(const Key('event-save')), findsNothing);
    expect(b.called('GET /api/eventi').length, greaterThanOrEqualTo(2));
  });

  testWidgets('cancelling the date picker leaves the date unset', (
    tester,
  ) async {
    final b = signedInBackend();
    await pumpApp(tester, b);
    await openForm(tester);
    await tester.tap(find.byKey(const Key('event-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('event-save')));
    await tester.pump();
    expect(find.text('Scegli data e ora'), findsOneWidget);
  });

  testWidgets('a server error keeps the form open', (tester) async {
    final b = signedInBackend();
    b.json('POST /api/eventi', {'error': 'Unauthorized'}, status: 400);
    await pumpApp(tester, b);
    await openForm(tester);
    await tester.enterText(find.byKey(const Key('event-title')), 'Festa');
    await tester.enterText(find.byKey(const Key('event-place')), 'Lucca');
    await tester.enterText(find.byKey(const Key('event-description')), 'x');
    await tester.tap(find.byKey(const Key('event-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('event-save')));
    await tester.pumpAndSettle();
    expect(find.text('Unauthorized'), findsOneWidget);
    expect(find.byKey(const Key('event-save')), findsOneWidget);
  });
}
