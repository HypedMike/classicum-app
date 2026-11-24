import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'config.dart';
import 'data/api_client.dart';
import 'data/repository.dart';
import 'data/token_store.dart';
import 'state/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('it');
  final api = ApiClient(baseUrl: kApiBaseUrl, tokens: SecureTokenStore());
  final repository = AdminRepository(api);
  final auth = AuthController(repository)..restore();
  runApp(ClassicumApp(repository: repository, auth: auth));
}
