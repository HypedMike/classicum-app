import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:classicum_admin/app/app.dart';
import 'package:classicum_admin/app/dependencies.dart';
import 'package:classicum_admin/core/config.dart';
import 'package:classicum_admin/core/network/api_client.dart';
import 'package:classicum_admin/core/network/token_store.dart';
import 'package:classicum_admin/features/auth/presentation/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('it');
  final api = ApiClient(baseUrl: kApiBaseUrl, tokens: SecureTokenStore());
  final deps = AppDependencies(api);
  final auth = AuthController(deps.auth)..restore();
  runApp(ClassicumApp(deps: deps, auth: auth));
}
