import 'package:dio/dio.dart';

import '../api_exception.dart';
import '../date_x.dart';

/// Validates the structure of OUTGOING requests before they hit the network.
/// Fails fast with a clear ApiException (no wasted round-trip) when the client
/// would send something the API will reject — a mutation without an auth token,
/// or a malformed booking body.
///
/// Matches on `options.path` (the relative path the repository passed), so it
/// works whether the base URL is local or a deployed Cloud Function.
class RequestValidationInterceptor extends Interceptor {
  bool _hasBearer(RequestOptions o) {
    final auth = o.headers['Authorization'];
    return auth is String && auth.startsWith('Bearer ');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final method = options.method.toUpperCase();
    final path = options.path.split('?').first;
    final problems = <String>[];

    if (method == 'POST' && path == '/bookings') {
      if (!_hasBearer(options)) problems.add('auth token');
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
      if (!_hasBearer(options)) problems.add('auth token');
    } else if (method == 'GET' && RegExp(r'^/users/[^/]+/bookings$').hasMatch(path)) {
      if (!_hasBearer(options)) problems.add('auth token');
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
