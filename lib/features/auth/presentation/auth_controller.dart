import 'package:flutter/foundation.dart';
import 'package:classicum_admin/core/network/api_client.dart';
import 'package:classicum_admin/features/auth/data/admin_user.dart';
import 'package:classicum_admin/features/auth/data/auth_repository.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthController extends ChangeNotifier {
  AuthController(this._repo) {
    _repo.onSessionExpired = _expired;
  }

  final AuthRepository _repo;

  AuthStatus status = AuthStatus.unknown;
  AdminUser? user;

  /// Restores a previous session, if any.
  Future<void> restore() async {
    try {
      user = await _repo.currentUser();
    } on ApiException {
      // Offline at launch: keep the stored session, we'll retry on first call.
      user = null;
    }
    status = user == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    user = await _repo.login(email, password);
    status = AuthStatus.signedIn;
    notifyListeners();
  }

  Future<void> logout() async {
    await _repo.logout();
    user = null;
    status = AuthStatus.signedOut;
    notifyListeners();
  }

  void _expired() {
    user = null;
    status = AuthStatus.signedOut;
    notifyListeners();
  }
}
