import 'package:flutter/services.dart';

class OrientationManger {
  static bool _orientationLocked = false;

  static Future<void> lockOrientation(String orientation) async {
    final deviceOrientation = _deserializeDeviceOrientation(orientation);

    if (deviceOrientation == null) {
      await SystemChrome.setPreferredOrientations([]);
      _orientationLocked = false;
    } else {
      _orientationLocked = true;
      await SystemChrome.setPreferredOrientations([deviceOrientation]);
    }
  }

  static Future<void> unlockOrientation() async {
    if (_orientationLocked) {
      await SystemChrome.setPreferredOrientations([]);
      _orientationLocked = false;
    }
  }

  static List<String> deviceOrientations() {
    // portrait orientation isn't currently
    // supported by the camconnect camera driver.
    return [
      // 'PortraitUp',
      // 'PortraitDown',
      'LandscapeLeft',
      'LandscapeRight',
      // 'AutoOrientation',
    ];
  }
}

/// Return the device orientation for a given String.
DeviceOrientation? _deserializeDeviceOrientation(String str) {
  switch (str) {
    case 'PortraitUp':
      return DeviceOrientation.portraitUp;
    case 'PortraitDown':
      return DeviceOrientation.portraitDown;
    case 'LandscapeLeft':
      return DeviceOrientation.landscapeLeft;
    case 'LandscapeRight':
      return DeviceOrientation.landscapeRight;
    default:
      return null;
  }
}
