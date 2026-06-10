import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import 'api_exception.dart';
import 'app_config.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/dev_log_interceptor.dart';
import 'interceptors/request_validation_interceptor.dart';
import 'interceptors/response_validation_interceptor.dart';

/// Thin wrapper around a configured [Dio] instance.
///
/// Repositories call get/post/delete and receive already-decoded JSON. The
/// interceptor pipeline (in order) is:
///   1. AuthInterceptor             — attaches the Firebase ID token (Bearer)
///   2. RequestValidationInterceptor  — validates outgoing request structure
///   3. ResponseValidationInterceptor — validates incoming response structure
///   4. DevLogInterceptor             — console logging (debug builds only)
///
/// Every Dio failure is normalized to a single [ApiException].
class ApiClient {
  ApiClient({required Future<String?> Function() tokenProvider, Dio? dio})
      : _dio = dio ?? _build(tokenProvider);
  final Dio _dio;

  static Dio _build(Future<String?> Function() tokenProvider) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.requestTimeout,
        receiveTimeout: AppConfig.requestTimeout,
        sendTimeout: AppConfig.requestTimeout,
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );
    dio.interceptors.add(AuthInterceptor(tokenProvider));
    dio.interceptors.add(RequestValidationInterceptor());
    dio.interceptors.add(ResponseValidationInterceptor());
    if (kDebugMode) dio.interceptors.add(DevLogInterceptor());
    return dio;
  }

  Future<dynamic> get(String path) => _run(() => _dio.get(path));

  Future<dynamic> post(String path, {Object? body}) =>
      _run(() => _dio.post(path, data: body ?? const {}));

  Future<dynamic> delete(String path) => _run(() => _dio.delete(path));

  Future<dynamic> _run(Future<Response> Function() request) async {
    try {
      final res = await request();
      return res.data;
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(0, 'NETWORK', 'The request timed out.');
      case DioExceptionType.connectionError:
        return const ApiException(
          0,
          'NETWORK',
          'Could not reach the server. Is the API running, and is the base URL correct?',
        );
      default:
        break;
    }

    final res = e.response;
    if (res == null) {
      return ApiException(0, 'NETWORK', e.message ?? 'Network error.');
    }
    final data = res.data;
    final map = data is Map ? data : const {};
    return ApiException(
      res.statusCode ?? 0,
      (map['error'] ?? 'HTTP_${res.statusCode}').toString(),
      (map['message'] ?? 'Request failed (${res.statusCode}).').toString(),
    );
  }
}
