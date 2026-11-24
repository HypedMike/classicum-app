import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import 'particle_system.dart';

/// Gold particles that gather into the walls of Lucca, as on the website home.
/// Touching or hovering pushes the particles away; tapping scatters them.
class ParticleField extends StatefulWidget {
  const ParticleField({super.key, this.system});

  /// Injectable for tests.
  final ParticleSystem? system;

  @override
  State<ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<ParticleField>
    with SingleTickerProviderStateMixin {
  late final ParticleSystem _system = widget.system ?? ParticleSystem();
  late final Ticker _ticker = createTicker(_onTick);
  final _repaint = ValueNotifier<int>(0);
  Duration _last = Duration.zero;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce != _reduceMotion || (!reduce && !_ticker.isActive)) {
      _reduceMotion = reduce;
      if (reduce) {
        _ticker.stop();
        _system.settle();
        _repaint.value++;
      } else if (!_ticker.isActive) {
        _last = Duration.zero;
        _ticker.start();
      }
    }
  }

  void _onTick(Duration elapsed) {
    final dtMs = (elapsed - _last).inMicroseconds / 1000;
    _last = elapsed;
    // Clamp so a long pause (app in background) doesn't make particles jump.
    final frames = (dtMs / (1000 / 60)).clamp(0.0, 3.0);
    _system.step(elapsed.inMicroseconds / 1000, frames);
    _repaint.value++;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  void _point(PointerEvent e) => _system.pointer = e.localPosition;

  void _clear([PointerEvent? _]) => _system.pointer = null;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (_system.size != size) {
          _system.resize(size);
          if (_reduceMotion) _system.settle();
        }
        return Semantics(
          label: 'Animazione: particelle dorate che disegnano le Mura di Lucca',
          image: true,
          child: MouseRegion(
            onHover: _point,
            onExit: _clear,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) {
                _point(e);
                if (!_reduceMotion) _system.scatter();
              },
              onPointerMove: _point,
              onPointerUp: _clear,
              onPointerCancel: _clear,
              child: RepaintBoundary(
                child: CustomPaint(
                  size: size,
                  painter: _ParticlePainter(_system, _repaint),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.system, Listenable repaint) : super(repaint: repaint);

  final ParticleSystem system;
  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    // Particles that haven't launched yet are dimmed.
    for (final p in system.particles) {
      final formed = system.isFormedNow(p);
      _paint.color = p.target.color.withValues(alpha: formed ? 0.92 : 0.22);
      canvas.drawRect(
        Rect.fromLTWH(p.x, p.y, p.target.size, p.target.size),
        _paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.system != system;
}
