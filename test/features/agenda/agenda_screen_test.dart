import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  setUpAll(() => initializeDateFormatting('it'));
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
}
