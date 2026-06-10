import 'package:dio/dio.dart';

import '../api_exception.dart';
import '../date_x.dart';

/// Validates the structure of OUTGOING requests before they hit the network.
/// Fails fast with a clear ApiException (no wasted round-trip) when the client
/// would otherwise send something the API will reject — e.g. a booking without
/// an `X-User-Id` header or a malformed body.
///
/// We match on `options.path` (the relative path the repository passed, e.g.
/// '/bookings') rather than the full URL, so this works whether the base URL is
/// a local server or a deployed Cloud Function with an '/api' prefix.
class RequestValidationInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final method = options.method.toUpperCase();
    final path = options.path.split('?').first;
    final problems = <String>[];

    if (method == 'POST' && path == '/bookings') {
      final userId = options.headers['X-User-Id'];
      if (userId is! String || userId.trim().isEmpty) {
        problems.add('X-User-Id header');
      }
      final body = options.data;
      if (body is! Map) {
        problems.add('JSON body');
      } else {
        if (body['venueId'] is! String || (body['venueId'] as String).isEmpty) {
          problems.add('venueId (non-empty string)');
        }
        final date = body['date'];
        if (date is! String || DateX.parseYmd(date) == null) {
          problems.add('date (YYYY-MM-DD)');
        }
        if (body['hour'] is! int) {
          problems.add('hour (int)');
        }
      }
    } else if (method == 'DELETE' && path.startsWith('/bookings/')) {
      final userId = options.headers['X-User-Id'];
      if (userId is! String || userId.trim().isEmpty) {
        problems.add('X-User-Id header');
      }
    }

    if (problems.isNotEmpty) {
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
          error: ApiException(
            0,
            'INVALID_REQUEST',
            'Request blocked before sending — missing/invalid: ${problems.join(', ')}.',
          ),
        ),
      );
    }

    handler.next(options);
  }
}
