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
      bottomNavigationBar: _FloatingNavBar(
        tabs: _tabs,
        index: _index,
        onSelected: _go,
      ),
    );
  }
}

/// Rounded bar floating above the page, with a soft shadow (as in the mock-up).
class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.tabs,
    required this.index,
    required this.onSelected,
  });

  final List<({String label, IconData icon})> tabs;
  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        key: const Key('floating-nav-bar'),
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        decoration: BoxDecoration(
          color: Palette.ink,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2E141414),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 10),
        child: Row(
          children: [
            for (var i = 0; i < tabs.length; i++)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: i == index,
                  label: tabs[i].label,
                  excludeSemantics: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onSelected(i),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            tabs[i].icon,
                            size: 24,
                            color: i == index
                                ? Palette.gold
                                : const Color(0xFFD9D2C3),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tabs[i].label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: i == index
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: i == index
                                  ? Palette.cream
                                  : const Color(0xFFD9D2C3),
                            ),
                          ),
                        ],
                      ),
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
