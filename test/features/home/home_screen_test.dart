import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  setUpAll(() => initializeDateFormatting('it'));
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
}
