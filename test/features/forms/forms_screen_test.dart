import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../helpers/pump_app.dart';

void main() {
  setUpAll(() => initializeDateFormatting('it'));
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
}
