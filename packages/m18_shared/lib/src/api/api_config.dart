/// Where the API lives. Set at build time: `--dart-define-from-file=.env` (with `API_URL=...`) or `--dart-define=API_URL=...`.
class ApiConfig {
  static const String _apiUrl = String.fromEnvironment('API_URL');

  /// The API base URL including `/api`, e.g. `http://localhost:50000/api`.
  static String get baseUrl {
    if (_apiUrl.isEmpty) {
      throw StateError(
        'API_URL is not set. Run with --dart-define-from-file=.env (containing API_URL=http://localhost:50000/api) '
        'or --dart-define=API_URL=<url>.',
      );
    }
    return _apiUrl;
  }
}
