import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'wall_cloud.dart';

const _fov = 32 * math.pi / 180;
const _launchDurationMs = 2200.0;

/// The 3D scene of the website hero, in plain Dart: a perspective camera
/// looking down on the walls of Lucca, which sway slowly. A port of the
/// website's vertex shader (staggered launch, shimmer, pointer repulsion and
/// the "gather" orbit), with the projection done on the CPU so it can be drawn
/// with a single `drawRawAtlas` call.
class LuccaWallsScene {
  /// [distanceScale] pulls the camera back (1 = exactly the website framing),
  /// [alpha] overrides the brightness (the website dims it on narrow screens)
  /// and [pointScale] enlarges the points.
  LuccaWallsScene({
    WallCloud? cloud,
    math.Random? random,
    this.distanceScale = 1,
    this.alpha,
    this.pointScale = 1,
  }) : cloud = cloud ?? WallCloud.build(random) {
    _allocate();
  }

  final WallCloud cloud;
  final double distanceScale;
  final double? alpha;
  final double pointScale;

  /// Per particle: scale, 0, x, y (what `drawRawAtlas` expects).
  late Float32List transforms;

  /// Per particle: the sprite rectangle in the atlas (set by the painter).
  late Float32List rects;

  /// Per particle: ARGB tint (alpha = depth and launch fade).
  late Int32List colors;

  /// Per particle: x, y on screen, in logical pixels (centre of the point).
  late Float32List screen;

  /// Edge of the square glow sprite the painter uses.
  static const spriteSize = 32.0;

  Size _size = Size.zero;
  double _pixelRatio = 1;
  bool reducedMotion = false;

  // Camera.
  final double _tanHalf = math.tan(_fov / 2);
  double _dist = 3, _aspect = 1;
  double _groupX = 0, _alphaScale = 1, _scale = 1;
  final _pos = [0.0, 0.0, 0.0];
  final _fwd = [0.0, 0.0, -1.0];
  final _right = [1.0, 0.0, 0.0];
  final _up = [0.0, 1.0, 0.0];

  // Animation state.
  double? _originMs;
  double _gather = 0;
  double _gatherTarget = 0;
  double _sway = 0, _swayTarget = 0;
  double _lastMs = 0;
  double _rotation = -0.25;
  Offset? _ndc;
  final _pointer = [1e3, 1e3, 1e3];
  final _scratch = [0.0, 0.0, 0.0];

  Size get size => _size;
  double get gather => _gather;
  double get rotationY => _rotation;
  double get cameraDistance => _dist;
  bool get hasPointer => _ndc != null;

  void _allocate() {
    final n = cloud.count;
    transforms = Float32List(4 * n);
    rects = Float32List(4 * n);
    colors = Int32List(n);
    screen = Float32List(2 * n);
    for (var i = 0; i < n; i++) {
      rects[4 * i + 2] = spriteSize;
      rects[4 * i + 3] = spriteSize;
    }
  }

  /// Sets the size of the field (and the device pixel ratio).
  void resize(Size size, {double pixelRatio = 1}) {
    if (size.isEmpty) return;
    _size = size;
    _pixelRatio = math.min(pixelRatio, 2);
    _aspect = size.width / size.height;
    final wide = _aspect > 1.3;
    _dist =
        math.max(0.95 / (_tanHalf * _aspect), 0.72 / _tanHalf) * distanceScale;
    _groupX = wide ? math.min(0.55, (_aspect - 1.3) * 0.5) : 0;
    _alphaScale = alpha ?? (wide ? 1 : 0.5);
    _pos[0] = 0;
    _pos[1] = 0.6593846719714731 * _dist;
    _pos[2] = 0.7518057291408949 * _dist;
    // lookAt(0, 0.02, 0)
    var fx = 0 - _pos[0], fy = 0.02 - _pos[1], fz = 0 - _pos[2];
    final fl = math.sqrt(fx * fx + fy * fy + fz * fz);
    fx /= fl;
    fy /= fl;
    fz /= fl;
    _fwd[0] = fx;
    _fwd[1] = fy;
    _fwd[2] = fz;
    // right = normalize(forward x worldUp)
    var rx = -fz, rz = fx;
    final rl = math.sqrt(rx * rx + rz * rz);
    rx /= rl;
    rz /= rl;
    _right[0] = rx;
    _right[1] = 0;
    _right[2] = rz;
    // up = right x forward
    _up[0] = 0 * fz - 0 * fy;
    _up[1] = rz * fx - rx * fz;
    _up[2] = rx * fy - 0 * fx;
    _scale = size.height / (2 * _tanHalf);
  }

  /// Hover / drag position in the field, or null when the pointer left.
  void setPointer(Offset? position) {
    if (position == null || _size.isEmpty) {
      _ndc = null;
      _swayTarget = 0;
      return;
    }
    _ndc = Offset(
      position.dx / _size.width * 2 - 1,
      -(position.dy / _size.height * 2) + 1,
    );
    _swayTarget = 0.3 * _ndc!.dx;
  }

  /// A press gathers the particles around the pointer; releasing lets go.
  void setPressed(bool pressed) => _gatherTarget = pressed ? 1 : 0;

  /// Starts the assembly again from the scattered state.
  void restart() => _originMs = null;

  /// Advances the scene to [timeMs] (animation clock) and recomputes where
  /// every particle is on screen. [frames] is the time since the last update
  /// in 60 fps frames, used for the smoothing.
  void update(double timeMs, {double frames = 1}) {
    if (_size.isEmpty) return;
    _originMs ??= timeMs;
    final elapsed = reducedMotion ? 1e6 : timeMs - _originMs!;
    final secs = reducedMotion ? 0.0 : timeMs / 1000;
    _lastMs = timeMs;

    if (!reducedMotion) {
      final rate = _gatherTarget > _gather ? 0.008 : 0.025;
      _gather += (_gatherTarget - _gather) * (1 - math.pow(1 - rate, frames));
      _sway += (_swayTarget - _sway) * (1 - math.pow(1 - 0.05, frames));
    }
    _rotation =
        (reducedMotion ? 0 : 0.4 * math.sin(0.00035 * timeMs)) - 0.25 + _sway;

    _updatePointer();

    final cosR = math.cos(_rotation), sinR = math.sin(_rotation);
    final n = cloud.count;
    final target = cloud.target, start = cloud.start;
    final gatherOn = _gather > 0.0001;
    final pointerOn = _pointer[0].abs() < 100;
    final px = _pointer[0], py = _pointer[1], pz = _pointer[2];
    final minSize = 1.2 / _pixelRatio;
    final w = _size.width, h = _size.height;
    final th = _tanHalf;

    for (var i = 0; i < n; i++) {
      final ph = cloud.phase[i];
      final t = ((elapsed - cloud.delayMs[i]) / _launchDurationMs).clamp(
        0.0,
        1.0,
      );
      final inv = 1 - t;
      final e = 1 - inv * inv * inv;

      final sx = math.sin(secs * 1.2 + ph) * 0.004;
      final sy = math.cos(secs * 1.0 + ph * 1.3) * 0.004;
      final sz = math.sin(secs * 0.9 + ph * 0.7) * 0.004;
      final dx = math.sin(secs * 0.6 + ph) * 0.03;
      final dy = math.cos(secs * 0.7 + ph) * 0.03;
      final dz = math.sin(secs * 0.5 + ph * 2.0) * 0.03;

      var x = (start[3 * i] + dx) * (1 - e) + (target[3 * i] + sx) * e;
      var y = (start[3 * i + 1] + dy) * (1 - e) + (target[3 * i + 1] + sy) * e;
      var z = (start[3 * i + 2] + dz) * (1 - e) + (target[3 * i + 2] + sz) * e;

      var g = 0.0;
      if (gatherOn) {
        g = (_gather * 1.5 - ph * 0.12).clamp(0.0, 1.0);
        g = g * g * (3 - 2 * g);
      }

      if (pointerOn) {
        final ddx = x - px, ddy = y - py, ddz = z - pz;
        final dist = math.sqrt(ddx * ddx + ddy * ddy + ddz * ddz);
        const r = 0.3;
        if (dist < r) {
          final len = math.sqrt(
            (ddx + 1e-5) * (ddx + 1e-5) +
                (ddy + 1e-5) * (ddy + 1e-5) +
                (ddz + 1e-5) * (ddz + 1e-5),
          );
          final k = (r - dist) / r * 0.18 * (1 - g) / len;
          x += (ddx + 1e-5) * k;
          y += (ddy + 1e-5) * k;
          z += (ddz + 1e-5) * k;
        }
      }

      if (g > 0) {
        var ox = math.sin(ph * 3.1),
            oy = math.cos(ph * 2.3),
            oz = math.sin(ph * 1.7 + 1.0);
        final ol = math.sqrt(ox * ox + oy * oy + oz * oz);
        ox /= ol;
        oy /= ol;
        oz /= ol;
        final rad = 0.03 + 0.12 * _fract(ph * 7.3);
        final ang = secs * (0.8 + _fract(ph * 5.0));
        final ca = math.cos(ang), sa = math.sin(ang);
        final tx = px + (ox * ca - oz * sa) * rad;
        final ty = py + oy * rad;
        final tz = pz + (ox * sa + oz * ca) * rad;
        x += (tx - x) * g;
        y += (ty - y) * g;
        z += (tz - z) * g;
      }

      // Model -> world (group rotation about Y, then offset).
      final wx = x * cosR + z * sinR + _groupX;
      final wy = y;
      final wz = -x * sinR + z * cosR;

      // World -> camera.
      final vx = wx - _pos[0], vy = wy - _pos[1], vz = wz - _pos[2];
      final zc = vx * _fwd[0] + vy * _fwd[1] + vz * _fwd[2];
      final xc = vx * _right[0] + vy * _right[1] + vz * _right[2];
      final yc = vx * _up[0] + vy * _up[1] + vz * _up[2];

      final ndcX = xc / (zc * th * _aspect);
      final ndcY = yc / (zc * th);
      final sxp = (ndcX * 0.5 + 0.5) * w;
      final syp = (0.5 - ndcY * 0.5) * h;

      final pointSize = math.max(
        minSize,
        cloud.size[i] * pointScale * _scale / zc,
      );
      final depthN = ((zc - (_dist - 1.3)) / 2.6).clamp(0.0, 1.0);
      final alpha = (1 - 0.7 * depthN) * (0.25 + 0.75 * e) * _alphaScale;

      screen[2 * i] = sxp;
      screen[2 * i + 1] = syp;
      final s = pointSize / spriteSize;
      transforms[4 * i] = s;
      transforms[4 * i + 1] = 0;
      transforms[4 * i + 2] = sxp - s * spriteSize / 2;
      transforms[4 * i + 3] = syp - s * spriteSize / 2;

      final a = (alpha * 255).round().clamp(0, 255);
      final r8 = (cloud.color[3 * i] * 255).round();
      final g8 = (cloud.color[3 * i + 1] * 255).round();
      final b8 = (cloud.color[3 * i + 2] * 255).round();
      colors[i] = (a << 24) | (r8 << 16) | (g8 << 8) | b8;
    }
  }

  /// Moves the pointer into model space by casting a ray from the camera
  /// through the pointer onto the plane facing the camera through the walls.
  void _updatePointer() {
    final ndc = _ndc;
    if (ndc != null && !reducedMotion) {
      final dx =
          _fwd[0] +
          _right[0] * ndc.dx * _tanHalf * _aspect +
          _up[0] * ndc.dy * _tanHalf;
      final dy =
          _fwd[1] +
          _right[1] * ndc.dx * _tanHalf * _aspect +
          _up[1] * ndc.dy * _tanHalf;
      final dz =
          _fwd[2] +
          _right[2] * ndc.dx * _tanHalf * _aspect +
          _up[2] * ndc.dy * _tanHalf;
      // Plane through (0, 0.0325, 0) with the camera's forward as normal.
      final denom = dx * _fwd[0] + dy * _fwd[1] + dz * _fwd[2];
      if (denom.abs() > 1e-9) {
        final t =
            ((0 - _pos[0]) * _fwd[0] +
                (0.0325 - _pos[1]) * _fwd[1] +
                (0 - _pos[2]) * _fwd[2]) /
            denom;
        final wx = _pos[0] + dx * t - _groupX;
        final wy = _pos[1] + dy * t;
        final wz = _pos[2] + dz * t;
        final c = math.cos(_rotation), s = math.sin(_rotation);
        // World -> model (inverse rotation about Y).
        _scratch[0] = wx * c - wz * s;
        _scratch[1] = wy;
        _scratch[2] = wx * s + wz * c;
        _pointer[0] = _scratch[0];
        _pointer[1] = _scratch[1];
        _pointer[2] = _scratch[2];
      }
    } else if (ndc == null && _gather < 0.01) {
      _pointer[0] = 1e3;
      _pointer[1] = 1e3;
      _pointer[2] = 1e3;
    }
  }

  double _fract(double v) => v - v.floorToDouble();

  /// For tests: the pointer in model space.
  List<double> get pointerModel => List.unmodifiable(_pointer);

  /// For tests: the clock of the last update.
  double get lastUpdateMs => _lastMs;
}
