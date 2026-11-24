import 'dart:math';
import 'dart:ui';

import 'package:classicum_admin/features/splash/presentation/lucca_walls_data.dart';
import 'package:classicum_admin/features/splash/presentation/particle_field.dart';
import 'package:classicum_admin/features/splash/presentation/wall_cloud.dart';
import 'package:classicum_admin/features/splash/presentation/wall_scene.dart';
import 'package:flutter_test/flutter_test.dart';

const portrait = Size(390, 560);

LuccaWallsScene scene({Size size = portrait, bool reduced = false}) {
  final s = LuccaWallsScene(random: Random(7))..reducedMotion = reduced;
  s.resize(size, pixelRatio: 2);
  return s;
}

/// Runs the scene at 60 fps for [seconds].
void run(LuccaWallsScene s, double seconds, {double from = 0}) {
  final steps = (seconds * 60).round();
  for (var i = 0; i <= steps; i++) {
    s.update(from + i * 1000 / 60);
  }
}

double distance(LuccaWallsScene s, int i, LuccaWallsScene ref) {
  final dx = s.screen[2 * i] - ref.screen[2 * i];
  final dy = s.screen[2 * i + 1] - ref.screen[2 * i + 1];
  return sqrt(dx * dx + dy * dy);
}

void main() {
  group('outline data', () {
    test('is the polygon of the real walls', () {
      expect(luccaWallOutline.length, 720 * 2);
      for (final v in luccaWallOutline) {
        expect(v, inInclusiveRange(-1.0, 1.0));
      }
    });

    test('the amphitheatre has four closed shapes', () {
      expect(luccaAmphitheatre, hasLength(4));
      for (final p in luccaAmphitheatre) {
        expect(p.length.isEven, isTrue);
        expect(p.length ~/ 2, greaterThanOrEqualTo(3));
      }
    });
  });

  group('WallCloud', () {
    final cloud = WallCloud.build(Random(1));

    test('has thousands of particles with consistent buffers', () {
      expect(cloud.count, inInclusiveRange(4000, 9000));
      expect(cloud.target.length, 3 * cloud.count);
      expect(cloud.start.length, 3 * cloud.count);
      expect(cloud.color.length, 3 * cloud.count);
      expect(cloud.size.length, cloud.count);
      expect(cloud.delayMs.length, cloud.count);
      expect(cloud.phase.length, cloud.count);
    });

    test('is deterministic for a given seed', () {
      final other = WallCloud.build(Random(1));
      expect(other.count, cloud.count);
      expect(other.start.first, cloud.start.first);
      expect(other.delayMs.last, cloud.delayMs.last);
    });

    test('walls are 0.065 high and the piazza is lower', () {
      var maxY = 0.0, minY = 1.0;
      for (var i = 0; i < cloud.count; i++) {
        final y = cloud.target[3 * i + 1];
        maxY = max(maxY, y);
        minY = min(minY, y);
      }
      expect(minY, 0);
      expect(maxY, closeTo(0.065, 1e-6));
    });

    test('uses the three brand colours', () {
      final colors = <String>{};
      for (var i = 0; i < cloud.count; i++) {
        colors.add(
          [
            cloud.color[3 * i],
            cloud.color[3 * i + 1],
            cloud.color[3 * i + 2],
          ].map((c) => (c * 255).round()).join(','),
        );
      }
      expect(colors, {'201,162,74', '140,116,52', '243,238,228'});
    });

    test('particles launch one after another over about two seconds', () {
      final delays = cloud.delayMs;
      expect(delays.reduce(min), greaterThanOrEqualTo(0));
      expect(delays.reduce(max), lessThanOrEqualTo(2100));
      expect(delays.toSet().length, greaterThan(cloud.count ~/ 2));
    });

    test('starts scattered well outside the walls', () {
      var outside = 0;
      for (var i = 0; i < cloud.count; i++) {
        final dx = cloud.start[3 * i] - cloud.target[3 * i];
        final dz = cloud.start[3 * i + 2] - cloud.target[3 * i + 2];
        if (sqrt(dx * dx + dz * dz) > 0.2) outside++;
      }
      expect(outside, greaterThan(cloud.count * 0.6));
    });
  });

  group('LuccaWallsScene', () {
    test('frames a portrait phone further back than a wide screen', () {
      final narrow = scene(size: const Size(390, 700));
      final wide = scene(size: const Size(1200, 700));
      expect(narrow.cameraDistance, greaterThan(wide.cameraDistance));
    });

    test('distanceScale pulls the camera back', () {
      final a = LuccaWallsScene(random: Random(1))..resize(portrait);
      final b = LuccaWallsScene(random: Random(1), distanceScale: 1.5)
        ..resize(portrait);
      expect(b.cameraDistance, closeTo(a.cameraDistance * 1.5, 1e-9));
    });

    test('ignores an empty size', () {
      final s = LuccaWallsScene(random: Random(1))..resize(Size.zero);
      s.update(0);
      expect(s.size, Size.zero);
    });

    test('assembled walls are projected inside the field', () {
      final s = scene();
      run(s, 5);
      var inside = 0;
      for (var i = 0; i < s.cloud.count; i++) {
        final x = s.screen[2 * i], y = s.screen[2 * i + 1];
        if (x >= 0 && x <= portrait.width && y >= 0 && y <= portrait.height) {
          inside++;
        }
      }
      expect(inside / s.cloud.count, greaterThan(0.95));
    });

    test('the walls are seen from above: wider than tall on screen', () {
      final s = scene();
      run(s, 5);
      var minX = 1e9, maxX = -1e9, minY = 1e9, maxY = -1e9;
      for (var i = 0; i < s.cloud.count; i++) {
        minX = min(minX, s.screen[2 * i]);
        maxX = max(maxX, s.screen[2 * i]);
        minY = min(minY, s.screen[2 * i + 1]);
        maxY = max(maxY, s.screen[2 * i + 1]);
      }
      expect(maxX - minX, greaterThan((maxY - minY) * 1.5));
    });

    test('nearer parts of the walls look brighter and larger', () {
      final s = scene();
      run(s, 5);
      // Compare the point lowest on screen (nearest) with the highest.
      var near = 0, far = 0;
      for (var i = 0; i < s.cloud.count; i++) {
        if (s.screen[2 * i + 1] > s.screen[2 * near + 1]) near = i;
        if (s.screen[2 * i + 1] < s.screen[2 * far + 1]) far = i;
      }
      int alpha(int i) => (s.colors[i] >> 24) & 0xFF;
      expect(alpha(near), greaterThanOrEqualTo(alpha(far)));
    });

    test('starts dim and scattered, then forms and brightens', () {
      final s = scene();
      s.update(0);
      final startAlpha = (s.colors[0] >> 24) & 0xFF;
      final startX = s.screen[0], startY = s.screen[1];
      run(s, 5);
      expect((s.colors[0] >> 24) & 0xFF, greaterThan(startAlpha));
      expect(
        (s.screen[0] - startX).abs() + (s.screen[1] - startY).abs(),
        greaterThan(1),
      );
    });

    test('reduced motion shows the finished drawing at once', () {
      final s = scene(reduced: true);
      s.update(0);
      final a = List<double>.of(s.screen.take(40));
      s.update(5000);
      expect(List<double>.of(s.screen.take(40)), a);
      expect(s.rotationY, closeTo(-0.25, 1e-9));
      expect((s.colors[0] >> 24) & 0xFF, greaterThan(60));
    });

    test('the assembled drawing matches the reduced-motion one', () {
      final animated = scene();
      final still = scene(reduced: true)..update(0);
      // Same seed -> same cloud. After the animation the walls only sway.
      run(animated, 5);
      final rotationOffset = animated.rotationY + 0.25;
      expect(rotationOffset.abs(), lessThan(0.4));
      expect(still.screen.length, animated.screen.length);
    });

    test('restart brings the particles back to their scattered start', () {
      final s = scene();
      run(s, 5);
      final formedAlpha = (s.colors[0] >> 24) & 0xFF;
      s.restart();
      s.update(6000);
      expect((s.colors[0] >> 24) & 0xFF, lessThan(formedAlpha));
    });

    /// The particle on the left edge of the walls: it lies close to the plane
    /// the pointer is cast on, so the pointer actually reaches it.
    int leftmost(LuccaWallsScene s) {
      var best = 0;
      for (var i = 0; i < s.cloud.count; i++) {
        if (s.screen[2 * i] < s.screen[2 * best]) best = i;
      }
      return best;
    }

    test('hovering pushes nearby particles away in 3D', () {
      final base = scene();
      final hover = scene();
      run(base, 5);
      run(hover, 5);
      final i = leftmost(hover);
      hover.setPointer(Offset(hover.screen[2 * i], hover.screen[2 * i + 1]));
      for (var k = 0; k < 20; k++) {
        base.update(5000 + k * 16.7);
        hover.update(5000 + k * 16.7);
      }
      // Compare the particles themselves (not the swaying camera): the walls
      // sway a little with the pointer, so measure relative to the centre.
      var moved = 0;
      for (var j = 0; j < hover.cloud.count; j++) {
        if (distance(hover, j, base) > 3) moved++;
      }
      expect(moved, greaterThan(20));
      expect(hover.hasPointer, isTrue);
    });

    test('letting go of the pointer sends the particles back', () {
      final base = scene();
      final hover = scene();
      run(base, 5);
      run(hover, 5);
      final i = leftmost(hover);
      hover.setPointer(Offset(hover.screen[2 * i], hover.screen[2 * i + 1]));
      for (var k = 0; k < 20; k++) {
        hover.update(5000 + k * 16.7);
      }
      hover.setPointer(null);
      for (var k = 0; k < 400; k++) {
        base.update(5000 + k * 16.7);
        hover.update(5000 + k * 16.7);
      }
      expect(hover.hasPointer, isFalse);
      expect(hover.pointerModel[0], 1e3);
      expect(distance(hover, i, base), lessThan(0.5));
    });

    test('pressing pulls particles to the pointer, releasing frees them', () {
      final s = scene();
      run(s, 5);
      final centre = Offset(portrait.width / 2, portrait.height / 2);
      s.setPointer(centre);
      s.setPressed(true);
      for (var k = 0; k < 400; k++) {
        s.update(5000 + k * 16.7);
      }
      expect(s.gather, greaterThan(0.9));
      var close = 0;
      for (var i = 0; i < s.cloud.count; i++) {
        final dx = s.screen[2 * i] - centre.dx;
        final dy = s.screen[2 * i + 1] - centre.dy;
        if (sqrt(dx * dx + dy * dy) < 60) close++;
      }
      expect(close, greaterThan(s.cloud.count * 0.8));

      s.setPressed(false);
      s.setPointer(null);
      for (var k = 0; k < 600; k++) {
        s.update(12000 + k * 16.7);
      }
      expect(s.gather, lessThan(0.01));
    });

    test('a long pause cannot make the particles explode', () {
      final s = scene();
      run(s, 5);
      s.update(30000, frames: 3);
      for (var i = 0; i < s.cloud.count; i++) {
        expect(s.screen[2 * i].isFinite, isTrue);
        expect(s.screen[2 * i + 1].isFinite, isTrue);
        expect(s.screen[2 * i], inInclusiveRange(-200, portrait.width + 200));
      }
    });

    test('fills the atlas buffers the painter draws', () {
      final s = scene();
      s.update(100);
      final n = s.cloud.count;
      expect(s.transforms.length, 4 * n);
      expect(s.rects.length, 4 * n);
      expect(s.colors.length, n);
      expect(s.rects[2], LuccaWallsScene.spriteSize);
      expect(s.rects[3], LuccaWallsScene.spriteSize);
      // The sprite is centred on the particle.
      final scale = s.transforms[0];
      expect(
        s.transforms[2] + scale * LuccaWallsScene.spriteSize / 2,
        closeTo(s.screen[0], 1e-3),
      );
    });

    test('points never get smaller than a device pixel', () {
      final s = scene();
      run(s, 5);
      final minLogical = 1.2 / 2;
      for (var i = 0; i < s.cloud.count; i++) {
        expect(
          s.transforms[4 * i] * LuccaWallsScene.spriteSize,
          greaterThanOrEqualTo(minLogical - 1e-6),
        );
      }
    });
  });

  test('the glow sprite is a soft round dot', () async {
    final image = buildGlowSprite();
    expect(image.width, LuccaWallsScene.spriteSize.toInt());
    final data = await image.toByteData();
    int alphaAt(int x, int y) => data!.getUint8((y * image.width + x) * 4 + 3);
    final c = image.width ~/ 2;
    expect(alphaAt(c, c), greaterThan(200)); // bright core
    expect(alphaAt(c, c), greaterThan(alphaAt(c + 12, c))); // falls off
    expect(alphaAt(0, 0), lessThan(5)); // transparent corners
    image.dispose();
  });
}
