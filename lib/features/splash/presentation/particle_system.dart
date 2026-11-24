import 'dart:math' as math;
import 'dart:ui';

/// A point of the target drawing (the walls of Lucca).
class ParticleTarget {
  const ParticleTarget(this.x, this.y, this.color, this.size);

  final double x;
  final double y;
  final Color color;
  final double size;
}

const _gold = Color(0xFFC9A24A);
const _darkGold = Color(0xFF8C7434);
const _cream = Color(0xFFF3EEE4);

const _outerCount = 780;
const _innerCount = 380;
const _ovalCount = 120;

/// Stylised outline of the walls of Lucca, the same used on the website home:
/// an east-west superellipse with 11 arrowhead bastions, an inner line for the
/// thickness of the wall, and the oval of Piazza dell'Anfiteatro.
List<ParticleTarget> luccaTargets(Size size) {
  final w = size.width, h = size.height;
  final cx = w / 2, cy = h / 2;
  final b = math.min((w * 0.40) / 1.45, h * 0.36);
  final a = b * 1.45;
  const n = 3.2;

  Offset superellipse(double t, double sa, double sb) {
    final ct = math.cos(t), st = math.sin(t);
    return Offset(
      ct.sign * math.pow(ct.abs(), 2 / n) * sa,
      st.sign * math.pow(st.abs(), 2 / n) * sb,
    );
  }

  final bastions = [
    for (var k = 0; k < 11; k++)
      k * 2 * math.pi / 11 + 0.18 + 0.08 * math.sin(k * 1.7),
  ];

  double bump(double t) {
    var best = 0.0;
    const width = 0.1;
    for (final bastion in bastions) {
      final d = math.atan2(math.sin(t - bastion), math.cos(t - bastion)).abs();
      if (d < width) {
        final v = d < width * 0.35
            ? 1 - 0.25 * d / (width * 0.35)
            : 0.75 * (1 - (d - width * 0.35) / (width * 0.65));
        if (v > best) best = v;
      }
    }
    return best;
  }

  final out = <ParticleTarget>[];
  for (var i = 0; i < _outerCount; i++) {
    final t = i / _outerCount * math.pi * 2;
    final p = superellipse(t, a, b);
    final len = math.sqrt(p.dx * p.dx + p.dy * p.dy);
    final safeLen = len == 0 ? 1 : len;
    final o = bump(t) * a * 0.11;
    out.add(
      ParticleTarget(
        cx + p.dx + p.dx / safeLen * o,
        cy + p.dy + p.dy / safeLen * o,
        _gold,
        1.6,
      ),
    );
  }
  for (var i = 0; i < _innerCount; i++) {
    final t = i / _innerCount * math.pi * 2;
    final p = superellipse(t, a * 0.9, b * 0.88);
    out.add(ParticleTarget(cx + p.dx, cy + p.dy, _darkGold, 1.2));
  }
  final ax = cx + a * 0.12, ay = cy - b * 0.25;
  for (var i = 0; i < _ovalCount; i++) {
    final t = i / _ovalCount * math.pi * 2;
    out.add(
      ParticleTarget(
        ax + math.cos(t) * a * 0.085,
        ay + math.sin(t) * a * 0.062,
        _cream,
        1.5,
      ),
    );
  }
  return out;
}

class Particle {
  Particle({
    required this.x,
    required this.y,
    required this.target,
    required this.delayMs,
    required this.phase,
  });

  double x;
  double y;
  double vx = 0;
  double vy = 0;
  ParticleTarget target;

  /// Time after which the particle starts flying towards its target.
  final double delayMs;
  final double phase;
}

/// Spring simulation: particles start scattered, then (staggered) fly to the
/// target drawing and hover around it. A pointer pushes them away.
class ParticleSystem {
  ParticleSystem({math.Random? random}) : _random = random ?? math.Random();

  final math.Random _random;
  final List<Particle> particles = [];
  Size _size = Size.zero;
  double? _originMs;
  double _nowMs = 0;
  bool _settled = false;

  /// Position of the finger / mouse in the field, if any.
  Offset? pointer;

  Size get size => _size;

  void resize(Size size) {
    if (size.isEmpty) return;
    _size = size;
    final targets = luccaTargets(size);
    if (particles.isEmpty) {
      for (var i = 0; i < targets.length; i++) {
        particles.add(
          Particle(
            x: _random.nextDouble() * size.width,
            y: _random.nextDouble() * size.height,
            target: targets[i],
            delayMs:
                (i % _outerCount) / _outerCount * 2400 +
                _random.nextDouble() * 300,
            phase: _random.nextDouble() * 6.283,
          ),
        );
      }
    } else {
      for (var i = 0; i < particles.length; i++) {
        particles[i].target = targets[i];
      }
    }
  }

  /// Throws every particle back to a random place; the drawing forms again.
  void scatter() {
    _originMs = null;
    _settled = false;
    for (final p in particles) {
      p.x = _random.nextDouble() * _size.width;
      p.y = _random.nextDouble() * _size.height;
      p.vx = 0;
      p.vy = 0;
    }
  }

  /// Puts every particle on its target (used when animations are disabled).
  void settle() {
    _settled = true;
    for (final p in particles) {
      p.x = p.target.x;
      p.y = p.target.y;
      p.vx = 0;
      p.vy = 0;
    }
  }

  /// Whether the particle is already flying to its target.
  bool isFormed(Particle p, double nowMs) =>
      nowMs - (_originMs ?? nowMs) > p.delayMs;

  /// [isFormed] at the time of the last [step] (or always, once settled).
  bool isFormedNow(Particle p) => _settled || isFormed(p, _nowMs);

  /// Advances the simulation. [nowMs] is the elapsed animation time and
  /// [frames] the elapsed time in 60 fps frames (1.0 = one frame).
  void step(double nowMs, double frames) {
    _originMs ??= nowMs;
    _nowMs = nowMs;
    final damping = math.pow(0.86, frames).toDouble();
    final ptr = pointer;
    for (final p in particles) {
      double ax, ay;
      if (isFormed(p, nowMs)) {
        ax =
            (p.target.x + math.sin(nowMs * 0.0012 + p.phase) * 1.3 - p.x) *
            0.018;
        ay =
            (p.target.y + math.cos(nowMs * 0.0010 + p.phase) * 1.3 - p.y) *
            0.018;
      } else {
        ax = math.sin(nowMs * 0.0006 + p.phase) * 0.02;
        ay = math.cos(nowMs * 0.0007 + p.phase) * 0.02;
      }
      if (ptr != null) {
        final dx = p.x - ptr.dx, dy = p.y - ptr.dy;
        final d2 = dx * dx + dy * dy;
        if (d2 < 4900) {
          final d = math.sqrt(d2);
          final dist = d == 0 ? 1 : d;
          final f = (70 - dist) / 70 * 1.6;
          ax += dx / dist * f;
          ay += dy / dist * f;
        }
      }
      p.vx = (p.vx + ax * frames) * damping;
      p.vy = (p.vy + ay * frames) * damping;
      p.x += p.vx * frames;
      p.y += p.vy * frames;
    }
  }
}
