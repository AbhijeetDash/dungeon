import 'package:dio/dio.dart';

/// Attaches the Firebase ID token to every request as `Authorization: Bearer`.
/// The token is fetched lazily per-request via the injected provider (which calls
/// FirebaseAuth.currentUser.getIdToken()), so it is always fresh and we never
/// store it. The backend verifies this token with the Admin SDK.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenProvider);
  final Future<String?> Function() _tokenProvider;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenProvider();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
