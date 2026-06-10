import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'app_config.dart';
import 'api_exception.dart';

/// Thin HTTP wrapper around our REST API.
///
/// Responsibilities (kept in ONE place so repositories stay clean):
///   • prefix every request with the configured base URL,
///   • attach JSON + the light-auth `X-User-Id` header,
///   • decode JSON, and
///   • translate any non-2xx response or transport failure into an [ApiException].
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path) => Uri.parse('${AppConfig.baseUrl}$path');

  Map<String, String> _headers(String? userId) => {
        'Content-Type': 'application/json',
        if (userId != null) 'X-User-Id': userId,
      };

  Future<dynamic> get(String path, {String? userId}) =>
      _send(() => _client.get(_uri(path), headers: _headers(userId)));

  Future<dynamic> post(String path, {Object? body, String? userId}) => _send(
        () => _client.post(
          _uri(path),
          headers: _headers(userId),
          body: jsonEncode(body ?? {}),
        ),
      );

  Future<dynamic> delete(String path, {String? userId}) =>
      _send(() => _client.delete(_uri(path), headers: _headers(userId)));

  /// Runs a request, applies the timeout, and normalizes errors.
  Future<dynamic> _send(Future<http.Response> Function() request) async {
    http.Response res;
    try {
      res = await request().timeout(AppConfig.requestTimeout);
    } on TimeoutException {
      throw const ApiException(0, 'NETWORK', 'The request timed out.');
    } on SocketException {
      throw const ApiException(
        0,
        'NETWORK',
        'Could not reach the server. Is the API running, and is the base URL correct?',
      );
    } catch (_) {
      throw const ApiException(0, 'NETWORK', 'Network error.');
    }

    final body = res.body.isEmpty ? null : jsonDecode(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }

    // Server responded with an error shape: { error, message }.
    final map = body is Map ? body : const {};
    throw ApiException(
      res.statusCode,
      (map['error'] ?? 'HTTP_${res.statusCode}').toString(),
      (map['message'] ?? 'Request failed (${res.statusCode}).').toString(),
    );
  }
}
