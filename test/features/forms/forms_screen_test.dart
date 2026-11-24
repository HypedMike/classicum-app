import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:http/http.dart' as http;
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

  testWidgets('draft forms are labelled and can be published', (tester) async {
    final b = signedInBackend();
    b.json('GET /api/form', {
      'items': [
        {
          'id': 'f2',
          'name': 'Bozza',
          'description': '',
          'published': false,
          'fields': [
            {'key': 'nome', 'type': 'string', 'value': ''},
          ],
        },
      ],
      'page': 1,
      'pageSize': 20,
      'total': 1,
      'totalPages': 1,
    });
    b.json('GET /api/form/f2/submissions', {
      'items': [],
      'page': 1,
      'pageSize': 20,
      'total': 0,
      'totalPages': 1,
    });
    b.routes['PUT /api/form/f2'] = (req) {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response(jsonEncode({'id': 'f2', ...body}), 200);
    };
    await pumpApp(tester, b);
    await tester.tap(find.text('Moduli').last);
    await tester.pumpAndSettle();
    expect(find.text('Bozza'), findsWidgets);
    expect(find.text('Pubblico'), findsNothing);
    await tester.tap(find.text('Bozza').last);
    await tester.pumpAndSettle();
    expect(find.text('Nessuna risposta.'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    final put = jsonDecode(b.called('PUT /api/form/f2').single.body);
    expect(put['published'], true);
    expect(put['fields'], [
      {'key': 'nome', 'type': 'string', 'value': ''},
    ]);
    expect(tester.widget<Switch>(find.byType(Switch)).value, true);
  });

  testWidgets('deleting a submission confirms and reloads', (tester) async {
    final b = signedInBackend();
    b.routes['DELETE /api/form/f1/submissions/s1'] = (_) =>
        http.Response('{}', 200);
    await pumpApp(tester, b);
    await tester.tap(find.text('Moduli').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Redazione Simulata'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Elimina risposta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();
    expect(b.called('DELETE /api/form/f1/submissions/s1'), hasLength(1));
    expect(b.called('GET /api/form/f1/submissions').length, 2);
  });

  testWidgets('a failing publish toggle shows the error', (tester) async {
    final b = signedInBackend();
    b.json('PUT /api/form/f1', {'error': 'Invalid form name'}, status: 400);
    await pumpApp(tester, b);
    await tester.tap(find.text('Moduli').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Redazione Simulata'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Invalid form name'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, true);
  });
}
