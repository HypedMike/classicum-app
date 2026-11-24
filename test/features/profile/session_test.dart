import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  setUpAll(() => initializeDateFormatting('it'));
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
        await b.deps.events.events();
      } catch (_) {}
    });
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-submit')), findsOneWidget);
  });
}
