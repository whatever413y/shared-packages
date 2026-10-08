import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'token_store.dart';

/// Thin JSON-over-HTTP client shared by all endpoint wrappers.
/// Every response whose status is not in `expected` throws [ApiException].
class ApiClient {
  final http.Client _http;
  final String? _baseUrl;
  final TokenStore tokens;

  /// [httpClient] and [baseUrl] are injectable for tests; by default the base URL comes from [ApiConfig].
  ApiClient({required this.tokens, http.Client? httpClient, this._baseUrl}) : _http = httpClient ?? http.Client();

  String get baseUrl => _baseUrl ?? ApiConfig.baseUrl;

  /// The URL of [path], with [query] parameters when there are any.
  Uri uri(String path, [Map<String, String>? query]) {
    final url = Uri.parse('$baseUrl$path');
    return query == null || query.isEmpty ? url : url.replace(queryParameters: query);
  }

  Future<Map<String, String>> headers({bool json = true}) async {
    final token = await tokens.token();
    return {if (json) 'Content-Type': 'application/json', if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token'};
  }

  Future<dynamic> get(String path, {Map<String, String>? query, Set<int> expected = const {200}}) async =>
      _decode(await _http.get(uri(path, query), headers: await headers()), expected);

  Future<dynamic> post(String path, {Object? body, Set<int> expected = const {200, 201}, Duration? timeout}) async {
    var request = _http.post(uri(path), headers: await headers(), body: body == null ? null : jsonEncode(body));
    if (timeout != null) request = request.timeout(timeout);
    return _decode(await request, expected);
  }

  Future<dynamic> put(String path, {Object? body, Set<int> expected = const {200}}) async =>
      _decode(await _http.put(uri(path), headers: await headers(), body: body == null ? null : jsonEncode(body)), expected);

  Future<dynamic> delete(String path, {Set<int> expected = const {204}}) async =>
      _decode(await _http.delete(uri(path), headers: await headers()), expected);

  /// Sends a multipart request (authorization header added here; http sets the multipart content type).
  Future<dynamic> send(http.MultipartRequest request, {Set<int> expected = const {200}}) async {
    request.headers.addAll(await headers(json: false));
    return _decode(await http.Response.fromStream(await _http.send(request)), expected);
  }

  dynamic _decode(http.Response response, Set<int> expected) {
    if (!expected.contains(response.statusCode)) throw ApiException(response.statusCode, response.body);
    return response.body.isEmpty ? null : jsonDecode(response.body);
  }
}
