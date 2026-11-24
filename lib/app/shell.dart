import 'package:material_ui/material_ui.dart';
import 'package:classicum_admin/core/theme.dart';
import 'package:classicum_admin/features/agenda/presentation/agenda_screen.dart';
import 'package:classicum_admin/features/forms/presentation/forms_screen.dart';
import 'package:classicum_admin/features/home/presentation/home_screen.dart';
import 'package:classicum_admin/features/messages/presentation/messages_screen.dart';
import 'package:classicum_admin/features/profile/presentation/profile_screen.dart';

/// Bottom navigation with the five sections from the mock-up.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  static const _tabs = [
    (label: 'Oggi', icon: Icons.home_outlined),
    (label: 'Agenda', icon: Icons.calendar_today_outlined),
    (label: 'Moduli', icon: Icons.assignment_outlined),
    (label: 'Messaggi', icon: Icons.mail_outline),
    (label: 'Profilo', icon: Icons.person_outline),
  ];

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onOpenTab: _go),
      const AgendaScreen(),
      const FormsScreen(),
      const MessagesScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Palette.ink,
          indicatorColor: Colors.transparent,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (s) => TextStyle(
              fontSize: 11,
              fontWeight: s.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: s.contains(WidgetState.selected)
                  ? Palette.cream
                  : const Color(0xFFD9D2C3),
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (s) => IconThemeData(
              color: s.contains(WidgetState.selected)
                  ? Palette.gold
                  : const Color(0xFFD9D2C3),
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _go,
          destinations: [
            for (final t in _tabs)
              NavigationDestination(icon: Icon(t.icon), label: t.label),
          ],
        ),
      ),
    );
  }
}
