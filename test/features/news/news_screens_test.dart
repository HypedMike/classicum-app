import 'dart:convert';

import 'package:classicum_admin/features/news/presentation/news_screens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/fake_backend.dart';
import '../../helpers/pump_app.dart';

Future<void> openNewsList(WidgetTester tester) async {
  await tester.tap(find.text('News').first);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('it'));

  testWidgets('news list shows items and loads more pages on demand', (
    tester,
  ) async {
    final b = signedInBackend();
    b.routes['GET /api/news'] = (req) {
      final page = int.parse(req.url.queryParameters['page'] ?? '1');
      final limit = int.parse(req.url.queryParameters['limit'] ?? '10');
      // Home asks for 3, the list asks for 10: 12 items in total.
      final all = [for (var i = 1; i <= 12; i++) newsJson('n$i', 'Notizia $i')];
      final slice = all.skip((page - 1) * limit).take(limit).toList();
      return http.Response(
        jsonEncode({
          'data': slice,
          'total': all.length,
          'page': page,
          'limit': limit,
        }),
        200,
      );
    };
    await pumpApp(tester, b);
    await tester.scrollUntilVisible(
      find.text('Gestisci'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(InkWell, 'News').first);
    await tester.pumpAndSettle();

    expect(find.text('Notizia 1'), findsOneWidget);
    expect(find.text('Notizia 12'), findsNothing);
    await tester.scrollUntilVisible(find.text('Carica altre'), 300);
    await tester.tap(find.text('Carica altre'));
    await tester.pumpAndSettle();
    expect(
      b.called('GET /api/news').map((r) => r.url.queryParameters['page']),
      contains('2'),
    );
    expect(find.text('Notizia 12', skipOffstage: false), findsOneWidget);
    expect(find.text('Carica altre'), findsNothing);
  });

  testWidgets('deleting a news item confirms, calls the API and reloads', (
    tester,
  ) async {
    final b = signedInBackend();
    b.routes['DELETE /api/news/n1'] = (_) => http.Response('ok', 200);
    await pumpApp(tester, b);
    await tester.tap(find.widgetWithText(InkWell, 'News').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Elimina Cerchio Verde'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();
    expect(b.called('DELETE /api/news/n1'), hasLength(1));
    expect(find.text('News eliminata'), findsOneWidget);
  });

  testWidgets('a failed load shows the error with a retry button', (
    tester,
  ) async {
    final b = signedInBackend();
    var fail = true;
    b.routes['GET /api/news'] = (req) {
      if (fail && req.url.queryParameters['limit'] == '10') {
        return http.Response(
          jsonEncode({'error': 'Database unavailable'}),
          503,
        );
      }
      return http.Response(
        jsonEncode({
          'data': [newsJson('n1', 'Cerchio Verde')],
          'total': 1,
          'page': 1,
          'limit': 10,
        }),
        200,
      );
    };
    await pumpApp(tester, b);
    await tester.tap(find.widgetWithText(InkWell, 'News').first);
    await tester.pumpAndSettle();
    expect(find.text('Database unavailable'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();
    expect(find.text('Cerchio Verde'), findsOneWidget);
  });

  testWidgets('new news requires title and text', (tester) async {
    final b = signedInBackend();
    await pumpApp(tester, b);
    await tester.tap(find.widgetWithText(InkWell, 'Nuova news'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('news-save')));
    await tester.pump();
    expect(find.text('Campo obbligatorio'), findsNWidgets(2));
    expect(b.called('POST /api/news'), isEmpty);
  });

  testWidgets('creating news posts paragraphs as HTML and closes the form', (
    tester,
  ) async {
    final b = signedInBackend();
    b.routes['POST /api/news'] = (_) => http.Response('{}', 201);
    await pumpApp(tester, b);
    await tester.tap(find.widgetWithText(InkWell, 'Nuova news'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('news-title')), 'Titolo');
    await tester.enterText(
      find.byKey(const Key('news-content')),
      'Primo\n\nSecondo <b>',
    );
    await tester.tap(find.byKey(const Key('news-save')));
    await tester.pumpAndSettle();
    final body = utf8.decode(b.called('POST /api/news').single.bodyBytes);
    expect(body, contains('<p>Primo</p><p>Secondo &lt;b&gt;</p>'));
    expect(body, contains('name="title"'));
    expect(find.byKey(const Key('news-save')), findsNothing);
  });

  testWidgets('a server error keeps the form open and shows the message', (
    tester,
  ) async {
    final b = signedInBackend();
    b.json('POST /api/news', {'error': 'Too many images'}, status: 400);
    await pumpApp(tester, b);
    await tester.tap(find.widgetWithText(InkWell, 'Nuova news'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('news-title')), 'T');
    await tester.enterText(find.byKey(const Key('news-content')), 'C');
    await tester.tap(find.byKey(const Key('news-save')));
    await tester.pumpAndSettle();
    expect(find.text('Too many images'), findsOneWidget);
    expect(find.byKey(const Key('news-save')), findsOneWidget);
  });

  testWidgets('editing prefills plain text and keeps existing images', (
    tester,
  ) async {
    final b = signedInBackend();
    b.routes['PUT /api/news/n1'] = (_) => http.Response('{}', 200);
    await pumpApp(tester, b);
    await tester.scrollUntilVisible(
      find.text('Cerchio Verde'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Cerchio Verde'));
    await tester.pumpAndSettle();
    expect(find.text('Modifica news'), findsOneWidget);
    expect(find.text('Testo di Cerchio Verde'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('news-title')), 'Nuovo titolo');
    await tester.tap(find.byKey(const Key('news-save')));
    await tester.pumpAndSettle();
    final body = utf8.decode(b.called('PUT /api/news/n1').single.bodyBytes);
    expect(body, contains('Nuovo titolo'));
    expect(body, contains('"fileId":"file-n1"'));
  });

  test('NewsHtml handles empty and whitespace-only input', () {
    expect(NewsHtml.toHtml(''), '');
    expect(NewsHtml.toHtml('  \n\n  '), '');
  });
}
