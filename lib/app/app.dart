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

class ClassicumApp extends StatelessWidget {
  const ClassicumApp({super.key, required this.deps, required this.auth});

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
