import 'dart:ui' show Tristate;

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

BoxDecoration decorationOf(WidgetTester tester, Key key) =>
    (tester.widget<Container>(find.byKey(key)).decoration! as BoxDecoration);

/// The painted box of a bar (without its outer margin).
Rect boxOf(WidgetTester tester, Key key) => tester.getRect(
  find
      .descendant(of: find.byKey(key), matching: find.byType(DecoratedBox))
      .first,
);

Tristate selected(WidgetTester tester, String label) => tester
    .getSemantics(find.bySemanticsLabel(label))
    .flagsCollection
    .isSelected;

void main() {
  setUpAll(() => initializeDateFormatting('it'));

  group('floating bottom bar', () {
    testWidgets('is rounded, dark and lifted with a soft shadow', (
      tester,
    ) async {
      await pumpApp(tester, signedInBackend());
      final d = decorationOf(tester, const Key('floating-nav-bar'));
      expect(d.borderRadius, BorderRadius.circular(20));
      expect(d.color, const Color(0xFF141414));
      expect(d.boxShadow, isNotEmpty);
      // Floats with a margin from the screen edges.
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      final rect = boxOf(tester, const Key('floating-nav-bar'));
      expect(rect.left, 12);
      expect(rect.right, screen.width - 12);
      expect(rect.bottom, lessThanOrEqualTo(screen.height - 12));
    });

    testWidgets('stays a bar and leaves the page its space', (tester) async {
      await pumpApp(tester, signedInBackend());
      final bar = boxOf(tester, const Key('floating-nav-bar')).size;
      expect(bar.height, inInclusiveRange(70, 100));
      expect(find.text('CIAO ANNA'), findsOneWidget);
    });

    testWidgets('shows the five sections and marks the current one', (
      tester,
    ) async {
      await pumpApp(tester, signedInBackend());
      for (final l in ['Oggi', 'Agenda', 'Moduli', 'Messaggi', 'Profilo']) {
        expect(find.text(l), findsWidgets);
      }
      expect(selected(tester, 'Oggi'), Tristate.isTrue);
      expect(selected(tester, 'Agenda'), Tristate.isFalse);
      await tester.tap(find.text('Messaggi').last);
      await tester.pumpAndSettle();
      expect(find.text('Marco Rossi'), findsOneWidget);
      expect(selected(tester, 'Messaggi'), Tristate.isTrue);
      expect(selected(tester, 'Oggi'), Tristate.isFalse);
    });
  });

  group('rounded top bar of the inner screens', () {
    Future<void> openNews(WidgetTester tester) async {
      await pumpApp(tester, signedInBackend());
      await tester.tap(find.widgetWithText(InkWell, 'News').first);
      await tester.pumpAndSettle();
    }

    testWidgets('is a dark rounded header with eyebrow and serif title', (
      tester,
    ) async {
      await openNews(tester);
      final d = decorationOf(tester, const Key('admin-top-bar'));
      expect(d.borderRadius, BorderRadius.circular(28));
      expect(d.color, const Color(0xFF141414));
      expect(d.boxShadow, isNotEmpty);
      expect(find.text('AMMINISTRATORE'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('admin-top-bar')),
          matching: find.text('News'),
        ),
        findsOneWidget,
      );
      expect(boxOf(tester, const Key('admin-top-bar')).left, 12);
    });

    testWidgets('the back arrow returns to the previous screen', (
      tester,
    ) async {
      await openNews(tester);
      await tester.tap(find.byTooltip('Indietro'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('admin-top-bar')), findsNothing);
      expect(find.text('CIAO ANNA'), findsOneWidget);
    });

    testWidgets('every inner screen uses it', (tester) async {
      await pumpApp(tester, signedInBackend());
      for (final label in ['Nuovo evento', 'Nuova news', 'Comunicati stampa']) {
        await tester.tap(find.widgetWithText(InkWell, label));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('admin-top-bar')),
          findsOneWidget,
          reason: label,
        );
        await tester.tap(find.byTooltip('Indietro'));
        await tester.pumpAndSettle();
      }
    });
  });
}
