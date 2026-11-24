import 'dart:math';

import 'package:classicum_admin/app/app.dart';
import 'package:classicum_admin/features/auth/presentation/auth_controller.dart';
import 'package:classicum_admin/features/splash/presentation/particle_field.dart';
import 'package:classicum_admin/features/splash/presentation/wall_scene.dart';
import 'package:classicum_admin/features/splash/presentation/splash_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/fake_backend.dart';
import '../../helpers/pump_app.dart';

Widget host(Widget child, {bool disableAnimations = false}) => MediaQuery(
  data: MediaQueryData(disableAnimations: disableAnimations),
  child: MaterialApp(home: child),
);

void main() {
  setUpAll(() => initializeDateFormatting('it'));

  LuccaWallsScene scene() => LuccaWallsScene(random: Random(3));

  testWidgets('the splash paints the particles and animates them', (
    tester,
  ) async {
    final s = scene();
    await tester.pumpWidget(host(Scaffold(body: ParticleField(scene: s))));
    await tester.pump(const Duration(milliseconds: 16));
    final before = s.screen[0];
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(s.screen[0], isNot(before));
    expect(
      find.descendant(
        of: find.byType(ParticleField),
        matching: find.byType(CustomPaint),
      ),
      findsWidgets,
    );
  });

  testWidgets('the walls sway while the particles settle', (tester) async {
    final s = scene();
    await tester.pumpWidget(host(Scaffold(body: ParticleField(scene: s))));
    final rotations = <double>{};
    for (var i = 0; i < 300; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      if (i % 50 == 0) rotations.add(s.rotationY);
    }
    expect(rotations.length, greaterThan(3));
  });

  testWidgets('pressing gathers the particles around the finger', (
    tester,
  ) async {
    final s = scene();
    await tester.pumpWidget(host(Scaffold(body: ParticleField(scene: s))));
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ParticleField)),
    );
    expect(s.hasPointer, isTrue);
    for (var i = 0; i < 150; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(s.gather, greaterThan(0.3));
    await gesture.up();
    expect(s.hasPointer, isFalse);
    for (var i = 0; i < 300; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(s.gather, lessThan(0.05));
  });

  testWidgets('with reduced motion the drawing is static and nothing ticks', (
    tester,
  ) async {
    final s = scene();
    await tester.pumpWidget(
      host(Scaffold(body: ParticleField(scene: s)), disableAnimations: true),
    );
    // No running ticker: pumpAndSettle returns immediately.
    await tester.pumpAndSettle();
    final first = List<double>.of(s.screen.take(20));
    // Tapping doesn't gather anything.
    await tester.tap(find.byType(ParticleField));
    await tester.pumpAndSettle();
    expect(s.gather, 0);
    expect(List<double>.of(s.screen.take(20)), first);
  });

  testWidgets('the splash screen shows the name and an accessible label', (
    tester,
  ) async {
    await tester.pumpWidget(host(const SplashScreen()));
    expect(find.text('Classicum'), findsOneWidget);
    expect(find.text('LE MURA · LUCCA'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Classicum, caricamento in corso'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Animazione: particelle dorate che disegnano in 3D le Mura di Lucca',
      ),
      findsOneWidget,
    );
  });

  group('app gate', () {
    testWidgets('shows the splash while the session is being restored', (
      tester,
    ) async {
      final b = FakeBackend(signedIn: false);
      final auth = AuthController(b.deps.auth); // status: unknown
      await tester.pumpWidget(
        ClassicumApp(deps: b.deps, auth: auth, minSplash: Duration.zero),
      );
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byKey(const Key('login-submit')), findsNothing);
    });

    testWidgets('keeps the splash for the minimum time, then moves on', (
      tester,
    ) async {
      final b = FakeBackend(signedIn: false);
      final auth = AuthController(b.deps.auth);
      await tester.pumpWidget(
        ClassicumApp(
          deps: b.deps,
          auth: auth,
          minSplash: const Duration(seconds: 3),
        ),
      );
      await auth.restore(); // ready right away, but the splash must stay
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byKey(const Key('login-submit')), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.byKey(const Key('login-submit')), findsOneWidget);
    });

    testWidgets('waits for the session even after the minimum time', (
      tester,
    ) async {
      final b = FakeBackend(signedIn: false);
      final auth = AuthController(b.deps.auth);
      await tester.pumpWidget(
        ClassicumApp(
          deps: b.deps,
          auth: auth,
          minSplash: const Duration(seconds: 1),
        ),
      );
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(SplashScreen), findsOneWidget);
      await auth.restore();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SplashScreen), findsNothing);
    });

    testWidgets('a signed-in user lands on the app after the splash', (
      tester,
    ) async {
      final b = signedInBackend();
      await pumpApp(tester, b);
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.text('CIAO ANNA'), findsOneWidget);
    });
  });
}
