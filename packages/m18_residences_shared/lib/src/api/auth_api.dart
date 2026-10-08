import '../models/bill_file_kind.dart';
import '../models/signed_file.dart';
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

  /// The login guards' answers, before the credentials are checked: 429 → [TooManyAttemptsException], 400 or 503
  /// (the captcha) → [VerificationFailedException].
  static ApiException? _guardError(ApiException e) => switch (e.statusCode) {
    429 => TooManyAttemptsException(e.statusCode, e.body),
    400 || 503 => VerificationFailedException(e.statusCode, e.body),
    _ => null,
  };

  /// [turnstileToken] is the login widget's token (single use). Throws [InvalidCredentialsException] on HTTP 401,
  /// [TooManyAttemptsException] on 429 and [VerificationFailedException] on 400/503.
  Future<AdminSession> adminLogin(String username, String password, {String? turnstileToken}) async {
    final dynamic data;
    try {
      data = await _client.post(
        '/auth/admin-login',
        body: {'username': username, 'password': password, 'turnstile_token': ?turnstileToken},
        expected: {200},
        timeout: loginTimeout,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401) throw InvalidCredentialsException(e.statusCode, e.body);
      throw _guardError(e) ?? e;
    }

    final token = data['token'] as String?;
    final name = data['username'] as String?;
    if (token == null || token.isEmpty || name == null || name.isEmpty) {
      throw const ApiException(200, 'Admin login response is missing token or username');
    }
    await tokens.save(token: token, subject: name);
    return AdminSession(token: token, username: name);
  }

  /// Tenants log in by name only (any case). [turnstileToken] is the login widget's token (single use). Throws
  /// [TenantNotFoundException] on HTTP 404, [TooManyAttemptsException] on 429 and [VerificationFailedException] on
  /// 400/503.
  Future<TenantSession> tenantLogin(String name, {String? turnstileToken}) async {
    final dynamic data;
    try {
      data = await _client.post('/auth/login', body: {'name': name, 'turnstile_token': ?turnstileToken}, expected: {200}, timeout: loginTimeout);
    } on ApiException catch (e) {
      if (e.statusCode == 404) throw TenantNotFoundException(e.statusCode, e.body);
      throw _guardError(e) ?? e;
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

  /// Short-lived link to bill [billId]'s receipt or payment image, wherever it is stored (404 when it has none).
  Future<SignedFile> signedBillFileUrl(int billId, BillFileKind kind) => _signedFile('/signed-urls/bills/$billId/${kind.subject}');

  /// Short-lived link to a payment method's QR image (404 when it has none).
  Future<SignedFile> signedPaymentMethodUrl(int id) => _signedFile('/signed-urls/payment-methods/$id');

  Future<SignedFile> _signedFile(String path) async {
    final data = await _client.get(path) as Map<String, dynamic>;
    final url = data['url'];
    if (url is! String || url.isEmpty) throw const ApiException(200, 'Signed URL response is missing url');
    return SignedFile.fromJson(data);
  }
}
