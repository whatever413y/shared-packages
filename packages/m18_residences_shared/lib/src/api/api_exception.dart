import 'dart:convert';

/// The API answered with a status the caller did not expect.
class ApiException implements Exception {
  final int statusCode;
  final String body;

  const ApiException(this.statusCode, this.body);

  /// The server's `{"error": "..."}` message when present, otherwise the raw body.
  String get message {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['error'] is String) return decoded['error'] as String;
    } on FormatException {
      // Not JSON; fall back to the raw body.
    }
    return body;
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Admin login rejected (HTTP 401).
class InvalidCredentialsException extends ApiException {
  const InvalidCredentialsException(super.statusCode, super.body);
}

/// Tenant login for a name that does not exist (HTTP 404).
class TenantNotFoundException extends ApiException {
  const TenantNotFoundException(super.statusCode, super.body);
}

/// Too many login attempts from this client (HTTP 429); the server allows more after a minute.
class TooManyAttemptsException extends ApiException {
  const TooManyAttemptsException(super.statusCode, super.body);
}

/// The login's captcha (Cloudflare Turnstile) was not accepted (HTTP 400), or could not be checked right now
/// ([unavailable], HTTP 503). Either way the widget needs a new token before the next try.
class VerificationFailedException extends ApiException {
  const VerificationFailedException(super.statusCode, super.body);

  /// Cloudflare could not be reached: try again later rather than solve the check again.
  bool get unavailable => statusCode == 503;
}
