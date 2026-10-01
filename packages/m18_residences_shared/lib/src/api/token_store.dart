import 'package:shared_preferences/shared_preferences.dart';

/// Persists the session: the JWT under `auth_token` plus the logged-in subject
/// (`admin_id` in the admin app, `tenant_id` in the tenant app) — the same keys the apps always used.
class TokenStore {
  static const String tokenKey = 'auth_token';

  final String subjectKey;

  const TokenStore(this.subjectKey);

  Future<String?> token() async => (await SharedPreferences.getInstance()).getString(tokenKey);

  Future<String?> subject() async => (await SharedPreferences.getInstance()).getString(subjectKey);

  Future<void> save({required String token, required String subject}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
    await prefs.setString(subjectKey, subject);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(subjectKey);
  }
}
