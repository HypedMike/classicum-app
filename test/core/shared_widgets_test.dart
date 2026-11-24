import 'dart:io';

import 'package:classicum_admin/core/network/api_client.dart';
import 'package:classicum_admin/core/network/token_store.dart';
import 'package:classicum_admin/core/network/uploads.dart';
import 'package:classicum_admin/core/ui/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  setUpAll(() => initializeDateFormatting('it'));

  group('formatting', () {
    final d = DateTime(2026, 3, 7, 18, 5);

    test('dates use Italian month names', () {
      expect(formatDate(d), '7 mar 2026');
      expect(formatDay(d), '7');
      expect(formatMonth(d), 'MAR');
      expect(formatTime(d), '18:05');
    });

    test('errorText prefers the API message', () {
      expect(errorText(ApiException(400, 'Brutto')), 'Brutto');
      expect(errorText(StateError('x')), 'Qualcosa è andato storto');
    });

    test('stripHtml decodes entities and keeps paragraph breaks', () {
      expect(
        stripHtml(
          '<p>A&nbsp;&amp;&nbsp;B</p><p>&lt;c&gt; &quot;d&quot; &#39;e&#39;</p>',
        ),
        'A & B\n<c> "d" \'e\'',
      );
      expect(stripHtml('Uno<br>Due<br/>Tre'), 'Uno\nDue\nTre');
      expect(stripHtml('<p>a</p>



<p>b</p>'), 'a

b');
    });
  });

  group('widgets', () {
    Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

    testWidgets('FilterPill reports taps and its selected state', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        host(FilterPill(label: 'Tutti', selected: true, onTap: () => taps++)),
      );
      await tester.tap(find.text('Tutti'));
      expect(taps, 1);
      expect(
        tester.getSemantics(find.text('Tutti')),
        matchesSemantics(
          label: 'Tutti',
          isButton: true,
          isSelected: true,
          hasTapAction: true,
          hasSelectedState: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
    });

    testWidgets('Pill renders filled and outlined variants', (tester) async {
      await tester.pumpWidget(
        host(
          const Column(
            children: [Pill('Pubblico'), Pill('Bozza', dark: false)],
          ),
        ),
      );
      expect(find.text('Pubblico'), findsOneWidget);
      expect(find.text('Bozza'), findsOneWidget);
    });

    testWidgets('ErrorView retries', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        host(
          ErrorView(
            error: ApiException(500, 'Rotto'),
            onRetry: () => retried = true,
          ),
        ),
      );
      expect(find.text('Rotto'), findsOneWidget);
      await tester.tap(find.text('Riprova'));
      expect(retried, isTrue);
    });

    testWidgets('RemoteImage shows a placeholder without a URL', (
      tester,
    ) async {
      await tester.pumpWidget(host(const RemoteImage(url: null)));
      expect(find.byType(Image), findsNothing);
      await tester.pumpWidget(host(const RemoteImage(url: '')));
      expect(find.byType(Image), findsNothing);
      await tester.pumpWidget(
        host(const RemoteImage(url: 'http://x.test/a.png')),
      );
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('EmptyView and PageHeader show their text', (tester) async {
      await tester.pumpWidget(
        host(
          const Column(
            children: [
              PageHeader(eyebrow: 'Sopra', title: 'Titolo'),
              EmptyView('Niente'),
            ],
          ),
        ),
      );
      expect(find.text('SOPRA'), findsOneWidget);
      expect(find.text('Titolo'), findsOneWidget);
      expect(find.text('Niente'), findsOneWidget);
    });
  });

  group('SecureTokenStore', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('persists, reads and clears tokens', () async {
      final store = SecureTokenStore();
      expect(await store.read(), isNull);
      await store.write(const AuthTokens(accessToken: 'a', refreshToken: 'r'));
      final read = await store.read();
      expect(read?.accessToken, 'a');
      expect(read?.refreshToken, 'r');
      await store.clear();
      expect(await store.read(), isNull);
    });

    test('a half-written session counts as signed out', () async {
      FlutterSecureStorage.setMockInitialValues({'access_token': 'a'});
      expect(await SecureTokenStore().read(), isNull);
    });
  });

  group('uploads', () {
    test('multipartFile detects the content type from the extension', () async {
      final dir = Directory.systemTemp.createTempSync('upl');
      addTearDown(() => dir.deleteSync(recursive: true));
      final cases = {
        'a.png': 'image/png',
        'a.WEBP': 'image/webp',
        'a.gif': 'image/gif',
        'a.jpg': 'image/jpeg',
        'a.heic': 'image/jpeg',
      };
      for (final entry in cases.entries) {
        final f = File('${dir.path}/${entry.key}')..writeAsBytesSync([1, 2, 3]);
        final part = multipartFile(
          'image',
          UploadImage(path: f.path, filename: entry.key),
        );
        expect(part.contentType.mimeType, entry.value, reason: entry.key);
        expect(part.length, 3);
        expect(part.filename, entry.key);
        expect(part.field, 'image');
      }
    });
  });
}
