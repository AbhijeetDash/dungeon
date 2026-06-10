import 'package:dio/dio.dart';

import '../api_exception.dart';

/// Validates the structure of INCOMING 2xx responses against the API contract.
/// If the backend ever drifts (a renamed key, a wrong type), we surface a clean
/// `BAD_RESPONSE` here instead of letting a null/cast error explode deep inside
/// a Bloc or widget. Only successful responses reach this (Dio routes non-2xx to
/// onError), so we only assert the happy-path shapes.
class ResponseValidationInterceptor extends Interceptor {
  static final _slots = RegExp(r'^/venues/[^/]+/slots$');
  static final _userBookings = RegExp(r'^/users/[^/]+/bookings$');

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final method = response.requestOptions.method.toUpperCase();
    final path = response.requestOptions.path.split('?').first;
    final data = response.data;

    // Parse guard: every endpoint returns a JSON object/array. If Dio handed us
    // anything else (e.g. an HTML error page from a wrong base URL), fail clearly.
    if (data is! Map && data is! List) {
      return handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: const ApiException(0, 'BAD_RESPONSE', 'Response body was not JSON.'),
        ),
      );
    }

    bool hasList(String key) => data is Map && data[key] is List;
    bool hasKeys(List<String> keys) =>
        data is Map && keys.every(data.containsKey);

    String? problem;
    if (method == 'GET' && path == '/venues') {
      if (!hasList('venues')) problem = 'expected { venues: [...] }';
    } else if (method == 'GET' && _slots.hasMatch(path)) {
      if (!hasList('slots')) problem = 'expected { slots: [...] }';
    } else if (method == 'GET' && path == '/users') {
      if (!hasList('users')) problem = 'expected { users: [...] }';
    } else if (method == 'GET' && _userBookings.hasMatch(path)) {
      if (!hasList('bookings')) problem = 'expected { bookings: [...] }';
    } else if (method == 'POST' && path == '/bookings') {
      if (!hasKeys(['id', 'venueId', 'date', 'hour', 'status'])) {
        problem = 'expected a booking with id/venueId/date/hour/status';
      }
    } else if (method == 'DELETE' && path.startsWith('/bookings/')) {
      if (!hasKeys(['status'])) problem = 'expected { status: ... }';
    }

    if (problem != null) {
      return handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: ApiException(
            0,
            'BAD_RESPONSE',
            'Unexpected response for $method $path — $problem.',
          ),
        ),
      );
    }

    handler.next(response);
  }
}
