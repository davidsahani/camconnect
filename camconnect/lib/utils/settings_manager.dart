import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'connection_manager.dart';
import 'orientation_manager.dart';
import 'preferences.dart';
import 'request_handler.dart';
import 'request_names.dart';

class SettingsManager {
  static void Function(int)? onPortChanged;

  static MediaStream? get localStream =>
      ConnectionManager.signaling.localStream;

  static void init() {
    ConnectionManager.localStream.listen((stream) async {
      Variables.isMicOn = Preferences.getMicEnabled();
      Variables.isTorchOn = false;

      final audioTracks = stream.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        audioTracks.first.onMute = () {
          Variables.isMicOn = false;
        };
        audioTracks.first.onUnMute = () {
          Variables.isMicOn = true;
        };
      }
      // hasTorch fails if it's called soon after stream change
      await Future.delayed(const Duration(seconds: 2));
      try {
        await getHasTorch(); // update hasTorch value after stream change
      } catch (_) {
        // ignore error: we can't do much, camera may or may not have torch.
      }
    });
  }

  static const _localStreamError = 'Local stream not started.';

  static Future<void> switchCamera() async {
    if (localStream == null) {
      throw 'switchCamera Failed: $_localStreamError';
    }
    Variables.isTorchOn = false;
    await Helper.switchCamera(localStream!.getVideoTracks().first);
  }

  static Future<void> setTorch(bool value) async {
    if (localStream == null) {
      throw 'setTorch Failed: $_localStreamError';
    }
    await localStream!.getVideoTracks().first.setTorch(value);
    Variables.isTorchOn = value;
  }

  static Future<bool> getHasTorch() async {
    if (localStream == null) {
      throw 'getHasTorch Failed: $_localStreamError';
    }
    try {
      Variables.hasTorch = await localStream!.getVideoTracks().first.hasTorch();
    } catch (_) {
      throw 'Failed to check camera torch availability.';
    }
    return Variables.hasTorch;
  }

  static void setMic(bool value) {
    if (localStream == null) {
      throw 'setMic Failed: $_localStreamError';
    }
    if (!Preferences.getMicEnabled()) {
      throw 'Mic is not enabled, enable mic in settings.';
    }
    localStream!.getAudioTracks().first.enabled = value;
    Variables.isMicOn = value;
  }

  static Future<List<Map<String, String>>> getCameras() async {
    return (await Helper.cameras)
        .map((e) => {'name': formatCameraLabel(e.label), 'id': e.deviceId})
        .toList();
  }

  static String formatCameraLabel(String labelText) {
    final String text;
    try {
      text = labelText.split(',')[1];
    } on RangeError catch (_) {
      return labelText;
    }
    final txs = text.trim().split(' ');
    if (txs.contains("Facing")) {
      txs.remove("Facing");
    }
    final result = txs.join().trim();
    if (result.isEmpty) return "";
    return result[0].toUpperCase() + result.substring(1);
  }

  static Resolution getResolution() {
    final dimensions =
        Preferences.getResolution().split('x').map((v) => int.parse(v));

    return Resolution(
      width: dimensions.first,
      height: dimensions.last,
      maxFps: Preferences.getMaxFps(),
    );
  }

  static Future<Map<ResolutionPreset, List<Resolution>>>
      getResolutionPresets() {
    if (localStream == null) {
      throw 'getResolutionPresets Failed: $_localStreamError';
    }
    return CustomHelper.getResolutionPresets(localStream!);
  }

  static Future<void> setPort(int port) async {
    await Preferences.setPort(port);
    RequestHandler.sendUpdate(RequestName.port, port);
    onPortChanged?.call(port);
  }

  static Future<void> setCameraId(int cameraId) async {
    await Preferences.setCameraId(cameraId);
    await ConnectionManager.signaling.updateConstrains();
    RequestHandler.sendUpdate(RequestName.cameraId, cameraId);
  }

  static Future<void> setFps(int framerate) async {
    await Preferences.setFps(framerate);
    await ConnectionManager.signaling.updateConstrains();
    RequestHandler.sendUpdate(RequestName.framerate, framerate);
  }

  static Future<void> setMaxFps(int framerate) async {
    await Preferences.setMaxFps(framerate);
    RequestHandler.sendUpdate(RequestName.maxFramerate, framerate);
  }

  static Future<void> setResolution(String resolution) async {
    await Preferences.setResolution(resolution);
    await ConnectionManager.signaling.updateConstrains();
    RequestHandler.sendUpdate(RequestName.resolution, resolution);
  }

  static Future<void> setOrientation(String orientation) async {
    if (ConnectionManager.isConnected) {
      OrientationManger.lockOrientation(orientation);
    }
    await Preferences.setOrientation(orientation);
  }

  static Future<bool> setMicEnabled(bool value) async {
    try {
      await Preferences.setMicEnabled(value);
      await ConnectionManager.signaling.updateConstrains();
    } catch (_) {
      await Preferences.setMicEnabled(false);
      ConnectionManager.signaling.updateConstrains();
      return false;
    }
    return true; // success
  }
}

class Variables {
  static void Function()? onChanged;

  static bool _isMicOn = false;
  static bool _hasTorch = true;
  static bool _isTorchOn = false;

  static bool get isMicOn => _isMicOn;
  static set isMicOn(bool value) {
    _isMicOn = value;
    onChanged?.call();
    RequestHandler.sendUpdate(RequestName.microphone, value);
  }

  static bool get hasTorch => _hasTorch;
  static set hasTorch(bool value) {
    _hasTorch = value;
    onChanged?.call();
    RequestHandler.sendUpdate(RequestName.hasTorch, value);
  }

  static bool get isTorchOn => _isTorchOn;
  static set isTorchOn(bool value) {
    _isTorchOn = value;
    onChanged?.call();
    RequestHandler.sendUpdate(RequestName.torch, value);
  }
}
