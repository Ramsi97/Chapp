/// Backend endpoint configuration.
///
/// Override at build/run time, e.g.:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
///
/// Defaults target the Android emulator, whose host loopback is 10.0.2.2.
/// For the iOS simulator use http://127.0.0.1:8000; for a physical device use
/// your computer's LAN IP. This must match the backend's PUBLIC_BASE_URL so
/// that media URLs resolve on-device.
class ApiConstants {
  const ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// WebSocket URL derived from [baseUrl] (http->ws, https->wss).
  static String get wsUrl => '${baseUrl.replaceFirst('http', 'ws')}/ws';
}
