import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Compact console logging for development. Attached only in debug builds (see
/// ApiClient._build), so it is a complete no-op in release. Prints one line per
/// request / response / error — handy for watching the booking traffic, and the
/// 409 "slot taken" race, live during the two-phone demo.
class DevLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final user = options.headers['X-User-Id'];
    debugPrint(
      '→ ${options.method} ${options.path}${user != null ? '  (user: $user)' : ''}',
    );
    if (options.data != null && options.data is! String) {
      debugPrint('  body: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
      '← ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.path}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    final detail = err.error ?? err.message;
    debugPrint(
      '✖ ${status ?? '-'} ${err.requestOptions.method} ${err.requestOptions.path} :: $detail',
    );
    handler.next(err);
  }
}
