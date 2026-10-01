import '../models/tenant.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'token_store.dart';

class AdminSession {
  final String token;
  final String username;

  const AdminSession({required this.token, required this.username});
}

class TenantSession {
  final String token;
  final Tenant tenant;

  const TenantSession({required this.token, required this.tenant});
}

/// Login, session validation and signed image URLs.
class AuthApi {
  static const Duration loginTimeout = Duration(seconds: 120);

  final ApiClient _client;

  AuthApi(this._client);

  TokenStore get tokens => _client.tokens;

  /// Throws [InvalidCredentialsException] on HTTP 401.
  Future<AdminSession> adminLogin(String username, String password) async {
    final dynamic data;
    try {
      data = await _client.post('/auth/admin-login', body: {'username': username, 'password': password}, expected: {200}, timeout: loginTimeout);
    } on ApiException catch (e) {
      if (e.statusCode == 401) throw InvalidCredentialsException(e.statusCode, e.body);
      rethrow;
    }

    final token = data['token'] as String?;
    final name = data['username'] as String?;
    if (token == null || token.isEmpty || name == null || name.isEmpty) {
      throw const ApiException(200, 'Admin login response is missing token or username');
    }
    await tokens.save(token: token, subject: name);
    return AdminSession(token: token, username: name);
  }

  /// Tenants log in by name only. Throws [TenantNotFoundException] on HTTP 404.
  Future<TenantSession> tenantLogin(String name) async {
    final dynamic data;
    try {
      data = await _client.post('/auth/login', body: {'name': name}, expected: {200}, timeout: loginTimeout);
    } on ApiException catch (e) {
      if (e.statusCode == 404) throw TenantNotFoundException(e.statusCode, e.body);
      rethrow;
    }

    final token = data['token'] as String?;
    final tenantJson = data['tenant'] as Map<String, dynamic>?;
    if (token == null || token.isEmpty || tenantJson == null) {
      throw const ApiException(200, 'Tenant login response is missing token or tenant');
    }
    final tenant = Tenant.fromJson(tenantJson);
    await tokens.save(token: token, subject: '${tenant.id}');
    return TenantSession(token: token, tenant: tenant);
  }

  /// `true` if the saved token is accepted, `false` if there is none or the server rejects it (401/403).
  /// Any other failure (server error, network) throws, so callers decide how to surface it.
  Future<bool> validateToken() async {
    final token = await tokens.token();
    if (token == null || token.isEmpty) return false;
    try {
      await _client.post('/auth/validate-token', expected: {200});
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) return false;
      rethrow;
    }
  }

  Future<void> logout() => tokens.clear();

  /// Short-lived URL for a bill receipt stored under `receipts/<tenant name>/<filename>`.
  Future<String> signedReceiptUrl(String tenantName, String filename) =>
      _signedUrl('/signed-urls/receipts/${Uri.encodeComponent(tenantName)}/${Uri.encodeComponent(filename)}');

  /// Short-lived URL for a payment QR image (`payments/<name>.png`).
  Future<String> signedPaymentUrl(String name) => _signedUrl('/signed-urls/payments/${Uri.encodeComponent(name)}');

  Future<String> _signedUrl(String path) async {
    final data = await _client.get(path);
    final url = data['url'] as String?;
    if (url == null || url.isEmpty) throw const ApiException(200, 'Signed URL response is missing url');
    return url;
  }
}
