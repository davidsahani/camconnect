import 'package:flutter/services.dart';

class DriverInterfaceDevice {
  DriverInterfaceDevice({
    required this.deviceName,
    required this.devicePath,
  });

  final String deviceName;
  final String devicePath;

  @override
  String toString() => "$deviceName: $devicePath";
}

class DriverInterface {
  static const MethodChannel _methodChannel =
      MethodChannel('FlutterWebRTC.Method');
  static const EventChannel _eventChannel =
      EventChannel('DriverInterface/VideoProcessingEvent');

  /// Gets video input devices device information.
  ///
  /// Throws: Exception on failure.
  static Future<List<DriverInterfaceDevice>> getDevices() async {
    try {
      final List<dynamic> response =
          await _methodChannel.invokeMethod('DriverInterface::GetDevices');

      return response
          .map<DriverInterfaceDevice>(
            (dynamic map) => DriverInterfaceDevice(
              deviceName: map['deviceName']!,
              devicePath: map['devicePath']!,
            ),
          )
          .toList();
    } on PlatformException catch (error) {
      throw '${error.code} Error: ${error.message}';
    }
  }

  /// Sets the active video device.
  ///
  /// Parameters:
  /// - [device]: The device to set as the active device.
  ///
  /// Throws: Exception on failure.
  static Future<void> setDevice(DriverInterfaceDevice device) async {
    try {
      await _methodChannel.invokeMethod(
          'DriverInterface::SetDevice', {'devicePath': device.devicePath});
    } on PlatformException catch (error) {
      throw '${error.code} Error: ${error.message}';
    }
  }

  /// Destroys the active video device.
  static Future<void> destroyDevice() async {
    await _methodChannel.invokeMethod('DriverInterface::DestroyDevice');
  }

  /// Releases active resources.
  /// Including the COM library and active devices.
  static Future<void> release() async {
    await _methodChannel.invokeMethod('DriverInterface::Release');
  }

  /// Starts sending video frames to the driver.
  static Future<void> startVideoProcessing() async {
    await _methodChannel.invokeMethod('DriverInterface::StartVideoProcessing');
  }

  /// Stops sending video frames to the driver.
  static Future<void> stopVideoProcessing() async {
    await _methodChannel.invokeMethod('DriverInterface::StopVideoProcessing');
  }

  static Stream<String>? _videoProcessingErrorStream;

  static Stream<String> get errorStream {
    _videoProcessingErrorStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((dynamic result) => result.toString());
    return _videoProcessingErrorStream!;
  }
}
