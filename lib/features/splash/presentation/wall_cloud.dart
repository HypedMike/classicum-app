import 'dart:math' as math;
import 'dart:typed_data';

import 'lucca_walls_data.dart';

const _wallHeight = 0.065;
const _amphitheatreHeight = 0.022;
const _outlineSamples = 1500;

const _gold = [201 / 255, 162 / 255, 74 / 255];
const _darkGold = [140 / 255, 116 / 255, 52 / 255];
const _cream = [243 / 255, 238 / 255, 228 / 255];

/// The particles of the walls of Lucca, in model space (1 unit = half the
/// width of the walls): where each one ends up, where it starts, and when it
/// launches. A port of the website's hero animation (Three.js points).
class WallCloud {
  WallCloud._(
    this.count,
    this.target,
    this.start,
    this.color,
    this.size,
    this.delayMs,
    this.phase,
  );

  final int count;

  /// x, y, z of the final position (3 floats per particle; y is up).
  final Float32List target;

  /// x, y, z of the scattered starting position.
  final Float32List start;

  /// r, g, b in 0..1.
  final Float32List color;

  /// Size in model units.
  final Float32List size;

  /// Milliseconds after which the particle launches.
  final Float32List delayMs;

  /// Random phase for the idle shimmer and drift.
  final Float32List phase;

  factory WallCloud.build([math.Random? random]) {
    final rnd = random ?? math.Random();
    final points = <_Point>[];
    final samples = _sampleOutline();

    // Top edge of the wall, and its foot every other sample.
    for (var t = 0; t < samples.length; t++) {
      final p = samples[t];
      points.add(_Point(p.x, _wallHeight, p.z, _gold, 0.0085));
      if (t % 2 == 0) points.add(_Point(p.x, 0, p.z, _darkGold, 0.0065));
    }
    // Vertical lines giving the wall its height.
    for (var t = 0; t < samples.length; t++) {
      if (t % 4 != 0) continue;
      final p = samples[t];
      for (var k = 1; k < 6; k++) {
        points.add(_Point(p.x, _wallHeight * k / 6, p.z, _darkGold, 0.0055));
      }
    }
    // The inner line (thickness of the wall).
    for (var t = 0; t < samples.length; t++) {
      if (t % 2 != 0) continue;
      final p = samples[t];
      points.add(
        _Point(
          p.x + 0.030212 * p.nx,
          _wallHeight,
          p.z + 0.030212 * p.nz,
          _darkGold,
          0.0062,
        ),
      );
    }
    // Piazza dell'Anfiteatro and its buildings.
    for (final polygon in luccaAmphitheatre) {
      final n = polygon.length ~/ 2;
      for (var r = 0; r < n; r++) {
        final x0 = polygon[2 * r], z0 = polygon[2 * r + 1];
        final x1 = polygon[((r + 1) % n) * 2];
        final z1 = polygon[((r + 1) % n) * 2 + 1];
        final steps = math.max(
          2,
          (math.sqrt((x1 - x0) * (x1 - x0) + (z1 - z0) * (z1 - z0)) / 0.0035)
              .round(),
        );
        for (var e = 0; e < steps; e++) {
          final f = e / steps;
          final x = x0 + (x1 - x0) * f, z = z0 + (z1 - z0) * f;
          points.add(_Point(x, _amphitheatreHeight, z, _cream, 0.0085));
          points.add(_Point(x, 0, z, _cream, 0.0065));
        }
        for (var e = 1; e < 4; e++) {
          points.add(
            _Point(x0, _amphitheatreHeight * e / 4, z0, _cream, 0.006),
          );
        }
      }
    }

    final n = points.length;
    final target = Float32List(3 * n);
    final start = Float32List(3 * n);
    final color = Float32List(3 * n);
    final size = Float32List(n);
    final delay = Float32List(n);
    final phase = Float32List(n);
    for (var i = 0; i < n; i++) {
      final p = points[i];
      target[3 * i] = p.x;
      target[3 * i + 1] = p.y;
      target[3 * i + 2] = p.z;
      color[3 * i] = p.rgb[0];
      color[3 * i + 1] = p.rgb[1];
      color[3 * i + 2] = p.rgb[2];
      size[i] = p.s;
      delay[i] = i % 900 / 900 * 1800 + 300 * rnd.nextDouble();
      phase[i] = 6.283 * rnd.nextDouble();
      start[3 * i] = (2 * rnd.nextDouble() - 1) * 1.5;
      start[3 * i + 1] = 0.7 * rnd.nextDouble() - 0.1;
      start[3 * i + 2] = (2 * rnd.nextDouble() - 1) * 1.1;
    }
    return WallCloud._(n, target, start, color, size, delay, phase);
  }
}

class _Point {
  const _Point(this.x, this.y, this.z, this.rgb, this.s);

  final double x, y, z;
  final List<double> rgb;
  final double s;
}

class _Sample {
  const _Sample(this.x, this.z, this.nx, this.nz);

  final double x, z, nx, nz;
}

/// Evenly spaced points along the outline, each with the normal of its edge.
List<_Sample> _sampleOutline() {
  final r = luccaWallOutline;
  final count = r.length ~/ 2;
  final cumulative = <double>[0];
  for (var e = 1; e <= count; e++) {
    final a = (e - 1) * 2, b = e % count * 2;
    cumulative.add(
      cumulative[e - 1] +
          math.sqrt(
            math.pow(r[b] - r[a], 2) + math.pow(r[b + 1] - r[a + 1], 2),
          ),
    );
  }
  final total = cumulative[count];
  final out = <_Sample>[];
  var i = 0;
  for (var e = 0; e < _outlineSamples; e++) {
    final length = e / _outlineSamples * total;
    while (i < count - 1 && cumulative[i + 1] < length) {
      i++;
    }
    final s = 2 * i, u = (i + 1) % count * 2;
    final span = cumulative[i + 1] - cumulative[i];
    final c = (length - cumulative[i]) / (span == 0 ? 1 : span);
    final x = r[s] + (r[u] - r[s]) * c;
    final z = r[s + 1] + (r[u + 1] - r[s + 1]) * c;
    var tx = r[u] - r[s], tz = r[u + 1] - r[s + 1];
    final m = math.sqrt(tx * tx + tz * tz);
    final len = m == 0 ? 1 : m;
    tx /= len;
    tz /= len;
    var nx = -tz, nz = tx;
    if (-(nx * x) + -(nz * z) < 0) {
      nx = -nx;
      nz = -nz;
    }
    out.add(_Sample(x, z, nx, nz));
  }
  return out;
}
