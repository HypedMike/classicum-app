import 'dart:math';
import 'dart:ui';

import 'package:classicum_admin/features/splash/presentation/particle_system.dart';
import 'package:flutter_test/flutter_test.dart';

const size = Size(390, 500);

ParticleSystem system() => ParticleSystem(random: Random(1))..resize(size);

double distanceToTarget(Particle p) =>
    sqrt(pow(p.x - p.target.x, 2) + pow(p.y - p.target.y, 2)).toDouble();

/// Runs [seconds] of animation at 60 fps.
void run(ParticleSystem s, double seconds, {double from = 0}) {
  final steps = (seconds * 60).round();
  for (var i = 1; i <= steps; i++) {
    s.step(from + i * 1000 / 60, 1);
  }
}

void main() {
  group('luccaTargets', () {
    final targets = luccaTargets(size);

    test('draws the outer wall, the inner wall and the amphitheatre', () {
      expect(targets, hasLength(780 + 380 + 120));
      expect(
        targets.where((t) => t.color == const Color(0xFFC9A24A)),
        hasLength(780),
      );
      expect(
        targets.where((t) => t.color == const Color(0xFF8C7434)),
        hasLength(380),
      );
      expect(
        targets.where((t) => t.color == const Color(0xFFF3EEE4)),
        hasLength(120),
      );
    });

    test('stays inside the field, centred', () {
      for (final t in targets) {
        expect(t.x, inInclusiveRange(0, size.width));
        expect(t.y, inInclusiveRange(0, size.height));
      }
      final cx =
          targets.map((t) => t.x).reduce((a, b) => a + b) / targets.length;
      final cy =
          targets.map((t) => t.y).reduce((a, b) => a + b) / targets.length;
      expect(cx, closeTo(size.width / 2, 15));
      expect(cy, closeTo(size.height / 2, 15));
    });

    test('is wider than tall (east-west walls)', () {
      final outer = targets.take(780);
      final width =
          outer.map((t) => t.x).reduce(max) - outer.map((t) => t.x).reduce(min);
      final height =
          outer.map((t) => t.y).reduce(max) - outer.map((t) => t.y).reduce(min);
      expect(width, greaterThan(height));
    });

    test('scales with the field', () {
      final big = luccaTargets(const Size(1000, 800));
      final bigWidth =
          big.take(780).map((t) => t.x).reduce(max) -
          big.take(780).map((t) => t.x).reduce(min);
      final smallWidth =
          targets.take(780).map((t) => t.x).reduce(max) -
          targets.take(780).map((t) => t.x).reduce(min);
      expect(bigWidth, greaterThan(smallWidth));
    });
  });

  group('ParticleSystem', () {
    test('ignores an empty size', () {
      final s = ParticleSystem()..resize(Size.zero);
      expect(s.particles, isEmpty);
    });

    test('starts scattered, away from the drawing', () {
      final s = system();
      final far = s.particles.where((p) => distanceToTarget(p) > 20).length;
      expect(far, greaterThan(s.particles.length * 0.9));
    });

    test('gathers on the target drawing over time', () {
      final s = system();
      run(s, 6);
      final off = s.particles.where((p) => distanceToTarget(p) > 6).length;
      expect(off, 0);
    });

    test('particles launch one after the other', () {
      final s = system();
      run(s, 1);
      final launched = s.particles.where((p) => s.isFormed(p, 1000)).length;
      expect(launched, greaterThan(0));
      expect(launched, lessThan(s.particles.length));
      run(s, 4, from: 1000);
      expect(s.particles.every((p) => s.isFormed(p, 5000)), isTrue);
    });

    test('the pointer pushes nearby particles away', () {
      final s = system();
      run(s, 6);
      final p = s.particles.first;
      final before = distanceToTarget(p);
      s.pointer = Offset(p.x - 5, p.y);
      for (var i = 0; i < 20; i++) {
        s.step(6000 + i * 16.7, 1);
      }
      expect(distanceToTarget(p), greaterThan(before + 3));
      // Let go: it springs back.
      s.pointer = null;
      run(s, 4, from: 6400);
      expect(distanceToTarget(p), lessThan(6));
    });

    test('far particles ignore the pointer', () {
      final s = system();
      run(s, 6);
      final p = s.particles.first;
      final x = p.x;
      s.pointer = Offset(p.x + 300, p.y + 300);
      s.step(7000, 1);
      expect((p.x - x).abs(), lessThan(0.5));
    });

    test('scatter throws particles away and the drawing forms again', () {
      final s = system();
      run(s, 6);
      s.scatter();
      expect(
        s.particles.where((p) => distanceToTarget(p) > 20).length,
        greaterThan(s.particles.length * 0.9),
      );
      run(s, 6, from: 7000);
      expect(s.particles.where((p) => distanceToTarget(p) > 6), isEmpty);
    });

    test('settle puts everything on the target at once', () {
      final s = system()..settle();
      expect(s.particles.every((p) => distanceToTarget(p) == 0), isTrue);
      expect(s.particles.every(s.isFormedNow), isTrue);
    });

    test('resizing moves the targets but keeps the particles', () {
      final s = system();
      final count = s.particles.length;
      s.resize(const Size(800, 600));
      expect(s.particles, hasLength(count));
      expect(s.size, const Size(800, 600));
      expect(s.particles.first.target.x, isNot(luccaTargets(size).first.x));
    });

    test('a long pause does not make the particles explode', () {
      final s = system();
      run(s, 6);
      // The widget clamps frames to 3; even so, nothing leaves the field.
      s.step(20000, 3);
      for (final p in s.particles) {
        expect(p.x, inInclusiveRange(-50, size.width + 50));
        expect(p.y, inInclusiveRange(-50, size.height + 50));
      }
    });
  });
}
