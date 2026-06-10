/// App-wide configuration.
///
/// `baseUrl` is injected at build/run time so the SAME app binary works whether
/// the API is local or deployed:
///
///   • iOS simulator / macOS / web:   defaults to http://localhost:8081
///   • Physical iPhone on your Wi-Fi:  pass your Mac's LAN IP, e.g.
///       flutter run --dart-define=API_BASE_URL=http://192.168.1.5:8081
///   • Deployed Cloud Function:
///       flutter run --dart-define=API_BASE_URL=https://us-central1-<proj>.cloudfunctions.net/api
class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8081',
  );

  /// Network timeout for API calls.
  static const Duration requestTimeout = Duration(seconds: 12);
}
