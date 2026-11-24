import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'data/repository.dart';
import 'state/auth_controller.dart';
import 'theme.dart';
import 'ui/login_screen.dart';
import 'ui/shell.dart';

class ClassicumApp extends StatelessWidget {
  const ClassicumApp({super.key, required this.repository, required this.auth});

  final AdminRepository repository;
  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AdminRepository>.value(value: repository),
        ChangeNotifierProvider<AuthController>.value(value: auth),
      ],
      child: MaterialApp(
        title: 'Classicum Admin',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    switch (context.watch<AuthController>().status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.signedOut:
        return const LoginScreen();
      case AuthStatus.signedIn:
        return const Shell();
    }
  }
}
