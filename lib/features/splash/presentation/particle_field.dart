import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import 'wall_scene.dart';

/// Gold particles that gather into the walls of Lucca, in 3D, as on the
/// website home: the walls sway under a tilted camera, the pointer pushes the
/// particles away, and pressing gathers them around the finger.
class ParticleField extends StatefulWidget {
  const ParticleField({super.key, this.scene});

  /// Injectable for tests.
  final LuccaWallsScene? scene;

  @override
  State<ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<ParticleField>
    with SingleTickerProviderStateMixin {
  late final LuccaWallsScene _scene =
      widget.scene ??
      // A little further back and brighter than the website hero, which has a
      // whole page to itself; here the walls must fit a phone screen.
      LuccaWallsScene(distanceScale: 1.22, alpha: 0.85, pointScale: 1.3);
  late final Ticker _ticker = createTicker(_onTick);
  final _repaint = ValueNotifier<int>(0);
  ui.Image? _sprite;
  Duration _last = Duration.zero;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _sprite = buildGlowSprite();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _scene.reducedMotion = reduce;
    if (reduce) {
      _ticker.stop();
      _started = false;
    } else if (!_started) {
      _started = true;
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final dtMs = (elapsed - _last).inMicroseconds / 1000;
    _last = elapsed;
    // Clamp so a long pause (app in background) doesn't make particles jump.
    final frames = (dtMs / (1000 / 60)).clamp(0.0, 3.0);
    _scene.update(elapsed.inMicroseconds / 1000, frames: frames);
    _repaint.value++;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    _sprite?.dispose();
    super.dispose();
  }

  void _point(PointerEvent e) => _scene.setPointer(e.localPosition);

  void _release([PointerEvent? _]) {
    _scene.setPointer(null);
    _scene.setPressed(false);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final ratio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
        if (_scene.size != size) {
          _scene.resize(size, pixelRatio: ratio);
          if (_scene.reducedMotion) {
            _scene.update(0);
          }
        }
        return Semantics(
          label: 'Animazione: particelle dorate che disegnano in 3D le Mura di Lucca',
          image: true,
          child: MouseRegion(
            onHover: _point,
            onExit: _release,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) {
                _point(e);
                if (!_scene.reducedMotion) _scene.setPressed(true);
              },
              onPointerMove: _point,
              onPointerUp: _release,
              onPointerCancel: _release,
              child: RepaintBoundary(
                child: CustomPaint(
                  size: size,
                  painter: _WallsPainter(_scene, _sprite, _repaint),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A soft round sprite: bright core with a wider glow, the same falloff as
/// the website's fragment shader (`core + glow`).
ui.Image buildGlowSprite() {
  const size = LuccaWallsScene.spriteSize;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  // Alpha as a function of the distance from the centre (0 .. 0.5 of the
  // sprite), sampled finely so the gradient is smooth.
  double smoothstep(double a, double b, double x) {
    final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  const steps = 16;
  final colors = <Color>[];
  final stops = <double>[];
  for (var i = 0; i <= steps; i++) {
    final d = i / steps * 0.5;
    final core = smoothstep(0.5, 0.15, d);
    final glow = smoothstep(0.5, 0.0, d) * 0.5;
    colors.add(Color.fromRGBO(255, 255, 255, (core + glow).clamp(0.0, 1.0)));
    stops.add(i / steps);
  }
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, size, size),
    Paint()
      ..shader = ui.Gradient.radial(
        const Offset(size / 2, size / 2),
        size / 2,
        colors,
        stops,
      ),
  );
  return recorder.endRecording().toImageSync(size.toInt(), size.toInt());
}

class _WallsPainter extends CustomPainter {
  _WallsPainter(this.scene, this.sprite, Listenable repaint)
    : super(repaint: repaint);

  final LuccaWallsScene scene;
  final ui.Image? sprite;
  final Paint _paint = Paint()
    ..blendMode = BlendMode.plus
    ..filterQuality = FilterQuality.low;

  @override
  void paint(Canvas canvas, Size size) {
    final image = sprite;
    if (image == null) return;
    // Additive blending, like the website: overlapping particles brighten.
    canvas.drawRawAtlas(
      image,
      scene.transforms,
      scene.rects,
      scene.colors,
      BlendMode.modulate,
      null,
      _paint,
    );
  }

  @override
  bool shouldRepaint(_WallsPainter old) => old.scene != scene;
}
