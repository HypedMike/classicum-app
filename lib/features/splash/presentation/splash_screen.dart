import 'package:material_ui/material_ui.dart';

import 'package:classicum_admin/core/theme.dart';
import 'package:classicum_admin/features/splash/presentation/particle_field.dart';

/// Loading screen shown while the session is restored: gold particles draw the
/// walls of Lucca, like the hero of the Classicum website.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.ink,
      body: SafeArea(
        child: Column(
          children: [
            const Expanded(child: ParticleField()),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Semantics(
                container: true,
                label: 'Classicum, caricamento in corso',
                child: ExcludeSemantics(
                  child: Column(
                    children: [
                      Text(
                        'Classicum',
                        style: displayStyle(56, color: Palette.cream),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'LE MURA · LUCCA',
                        style: eyebrowStyle(color: const Color(0xFFD9D2C3)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
