import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:classicum_admin/app/dependencies.dart';
import 'package:classicum_admin/app/shell.dart';
import 'package:classicum_admin/core/theme.dart';
import 'package:classicum_admin/features/agenda/data/events_repository.dart';
import 'package:classicum_admin/features/auth/presentation/auth_controller.dart';
import 'package:classicum_admin/features/auth/presentation/login_screen.dart';
import 'package:classicum_admin/features/comunicati/data/comunicati_repository.dart';
import 'package:classicum_admin/features/forms/data/forms_repository.dart';
import 'package:classicum_admin/features/messages/data/messages_repository.dart';
import 'package:classicum_admin/features/news/data/news_repository.dart';
import 'package:classicum_admin/features/splash/presentation/splash_screen.dart';

class ClassicumApp extends StatelessWidget {
  const ClassicumApp({
    super.key,
    required this.deps,
    required this.auth,
    this.minSplash = const Duration(milliseconds: 4400),
  });

  /// How long the splash stays up at least (long enough for the particles to
  /// draw the walls). Tests pass [Duration.zero].
  final Duration minSplash;

  final AppDependencies deps;
  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<EventsRepository>.value(value: deps.events),
        Provider<NewsRepository>.value(value: deps.news),
        Provider<ComunicatiRepository>.value(value: deps.comunicati),
        Provider<FormsRepository>.value(value: deps.forms),
        Provider<MessagesRepository>.value(value: deps.messages),
        ChangeNotifierProvider<AuthController>.value(value: auth),
      ],
      child: MaterialApp(
        title: 'Classicum Admin',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: _AuthGate(minSplash: minSplash),
      ),
    );
  }
}

/// Shows the particle splash while the session is restored, for at least
/// [minSplash] so the animation has time to form, then the right screen.
class _AuthGate extends StatefulWidget {
  const _AuthGate({required this.minSplash});

  final Duration minSplash;

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late bool _minElapsed = widget.minSplash == Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (!_minElapsed) {
      _timer = Timer(widget.minSplash, () {
        if (mounted) setState(() => _minElapsed = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthController>().status;
    final showSplash = status == AuthStatus.unknown || !_minElapsed;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: showSplash
          ? const SplashScreen(key: Key('splash'))
          : KeyedSubtree(key: const Key('content'), child: _screenFor(status)),
    );
  }

  Widget _screenFor(AuthStatus status) {
    switch (status) {
      case AuthStatus.unknown:
      case AuthStatus.signedOut:
        return const LoginScreen();
      case AuthStatus.signedIn:
        return const Shell();
    }
  }
}
