import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static SharedPreferences? _preferences;

  static Future<void> init() async =>
      _preferences = await SharedPreferences.getInstance();

  // Cached values
  static String? _resolution;
  static int? _port, _cameraId, _fps;
  static bool? _micEnabled, _wakeLockEnabled, _autoDimScreenEnabled;

  // Port
  static Future<bool> setPort(int port) {
    _port = port;
    return _preferences!.setInt('port', port);
  }

  static int getPort() => _port ??= (_preferences!.getInt('port') ?? 8080);

  // Camera Id
  static Future<bool> setCameraId(int cameraId) {
    _cameraId = cameraId;
    return _preferences!.setInt('camera-id', cameraId);
  }

  static int getCameraId() =>
      _cameraId ??= (_preferences!.getInt('camera-id') ?? 0);

  // Mic Enabled
  static Future<bool> setMicEnabled(bool value) {
    _micEnabled = value;
    return _preferences!.setBool('mic', value);
  }

  static bool getMicEnabled() =>
      _micEnabled ??= (_preferences!.getBool('mic') ?? false);

  // Framerate
  static Future<bool> setFps(int fps) {
    _fps = fps;
    return _preferences!.setInt('fps', fps);
  }

  static int getFps() => _fps ??= (_preferences!.getInt('fps') ?? 30);

  // Resolution
  static Future<void> setResolution(String resolution) {
    _resolution = resolution;
    return _preferences!.setString('resolution', resolution);
  }

  static String getResolution() =>
      _resolution ??= (_preferences!.getString('resolution') ?? '1280x720');

  // Max Framerate
  static Future<bool> setMaxFps(int fps) =>
      _preferences!.setInt('max-fps', fps);
  static int getMaxFps() => _preferences!.getInt('max-fps') ?? 30;

  // Orientation
  static Future<bool> setOrientation(String value) =>
      _preferences!.setString('orientation', value);
  static String getOrientation() =>
      _preferences!.getString('orientation') ?? 'LandscapeLeft';

  // Wake Lock
  static Future<bool> setWakeLockEnabled(bool value) {
    _wakeLockEnabled = value;
    return _preferences!.setBool('wake-lock', value);
  }

  static bool getWakeLockEnabled() =>
      _wakeLockEnabled ??= (_preferences!.getBool('wake-lock') ?? true);

  // Auto Dim Screen
  static Future<bool> setAutoDimScreenEnabled(bool value) {
    _autoDimScreenEnabled = value;
    return _preferences!.setBool('auto-dim-screen', value);
  }

  static bool getAutoDimScreenEnabled() => _autoDimScreenEnabled ??=
      _preferences!.getBool('auto-dim-screen') ?? true;
}
