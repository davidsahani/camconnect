import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static SharedPreferences? _preferences;

  static Future<void> init() async =>
      _preferences = await SharedPreferences.getInstance();

  static int? _port; // cached value

  // Port
  static Future<bool> setPort(int port) {
    _port = port; // set the port for cached access
    return _preferences!.setInt('port', port);
  }

  static int getPort() => _port ??= (_preferences!.getInt('port') ?? 8080);

  // Video Device Enabled
  static Future<bool> setVideoDeviceEnabled(bool state) =>
      _preferences!.setBool('video-device', state);
  static bool getVideoDeviceEnabled() =>
      _preferences!.getBool('video-device') ?? true;

  // Video Device Path
  static Future<bool> setVideoDevicePath(String value) =>
      _preferences!.setString('video-device-path', value);
  static String? getVideoDevicePath() =>
      _preferences!.getString('video-device-path');

  // Audio Device Id
  static Future<bool> setAudioDeviceId(String value) =>
      _preferences!.setString('audio-device-id', value);
  static String? getAudioDeviceId() =>
      _preferences!.getString('audio-device-id');
}
