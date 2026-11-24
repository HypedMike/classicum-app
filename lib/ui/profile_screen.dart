import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../state/auth_controller.dart';
import '../theme.dart';
import 'widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthController>().user?.email ?? '';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      children: [
        const PageHeader(eyebrow: 'Il tuo profilo', title: 'Profilo'),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Palette.ink,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Palette.gold),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AMMINISTRATORE',
                style: eyebrowStyle(color: const Color(0xFFD9D2C3)),
              ),
              const SizedBox(height: 12),
              Text(
                email,
                key: const Key('profile-email'),
                style: displayStyle(
                  30,
                  color: Palette.cream,
                ).copyWith(height: 1.1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Container(height: 2, color: Palette.ink),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Sito collegato'),
          subtitle: const Text(kApiBaseUrl),
        ),
        const Divider(height: 1),
        ListTile(
          key: const Key('logout'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Esci'),
          trailing: const Icon(Icons.arrow_forward),
          onTap: () async {
            final auth = context.read<AuthController>();
            await auth.logout();
          },
        ),
        const Divider(height: 1),
      ],
    );
  }
}
