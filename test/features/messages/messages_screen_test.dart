import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../helpers/pump_app.dart';

void main() {
  setUpAll(() => initializeDateFormatting('it'));
  testWidgets('messages list shows contact requests', (tester) async {
    await pumpApp(tester, signedInBackend());
    await tester.tap(find.text('Messaggi').last);
    await tester.pumpAndSettle();
    expect(find.text('Marco Rossi'), findsOneWidget);
    expect(find.text('Vorrei prenotare una sala'), findsOneWidget);
  });
}
