import 'package:classicum_admin/core/network/api_client.dart';
import 'package:classicum_admin/features/auth/data/admin_user.dart';

class AuthRepository {
  AuthRepository(this.api);

  final ApiClient api;

  /// Called when the refresh token is no longer valid.
  set onSessionExpired(void Function()? callback) =>
      api.onSessionExpired = callback;

  Future<AdminUser> login(String email, String password) async =>
      AdminUser.fromJson(await api.login(email.trim().toLowerCase(), password));

  Future<AdminUser?> currentUser() async {
    if (!await api.hasSession()) return null;
    try {
      final data = await api.getJson('/api/auth/me') as Map<String, dynamic>;
      return AdminUser.fromJson(data['user'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.isUnauthorized) return null;
      rethrow;
    }
  }

  Future<void> logout() => api.logout();
}
