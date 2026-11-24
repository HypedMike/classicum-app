import 'dart:math';

import 'package:classicum_admin/app/app.dart';
import 'package:classicum_admin/features/auth/presentation/auth_controller.dart';
import 'package:classicum_admin/features/splash/presentation/particle_field.dart';
import 'package:classicum_admin/features/splash/presentation/particle_system.dart';
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

  testWidgets('the splash paints the particles and animates them', (
    tester,
  ) async {
    final system = ParticleSystem(random: Random(3));
    await tester.pumpWidget(
      host(Scaffold(body: ParticleField(system: system))),
    );
    expect(system.particles, isNotEmpty);
    final before = system.particles.first.x;
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(system.particles.first.x, isNot(before));
    expect(
      find.descendant(
        of: find.byType(ParticleField),
        matching: find.byType(CustomPaint),
      ),
      findsWidgets,
    );
  });

  testWidgets('particles reach the drawing after a few seconds', (
    tester,
  ) async {
    final system = ParticleSystem(random: Random(3));
    await tester.pumpWidget(
      host(Scaffold(body: ParticleField(system: system))),
    );
    for (var i = 0; i < 200; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    final off = system.particles.where((p) {
      final dx = p.x - p.target.x, dy = p.y - p.target.y;
      return sqrt(dx * dx + dy * dy) > 6;
    });
    expect(off, isEmpty);
  });

  testWidgets('tapping scatters the particles again', (tester) async {
    final system = ParticleSystem(random: Random(3));
    await tester.pumpWidget(
      host(Scaffold(body: ParticleField(system: system))),
    );
    for (var i = 0; i < 200; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.tap(find.byType(ParticleField));
    final off = system.particles.where((p) {
      final dx = p.x - p.target.x, dy = p.y - p.target.y;
      return sqrt(dx * dx + dy * dy) > 20;
    });
    expect(off.length, greaterThan(system.particles.length * 0.8));
  });

  testWidgets('with reduced motion the drawing is static and nothing ticks', (
    tester,
  ) async {
    final system = ParticleSystem(random: Random(3));
    await tester.pumpWidget(
      host(
        Scaffold(body: ParticleField(system: system)),
        disableAnimations: true,
      ),
    );
    // No running ticker: pumpAndSettle returns immediately.
    await tester.pumpAndSettle();
    expect(
      system.particles.every((p) => p.x == p.target.x && p.y == p.target.y),
      isTrue,
    );
    // Tapping doesn't scatter it.
    await tester.tap(find.byType(ParticleField));
    expect(system.particles.first.x, system.particles.first.target.x);
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
        'Animazione: particelle dorate che disegnano le Mura di Lucca',
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
