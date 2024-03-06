import '../utils/connection_manager.dart';
import '../utils/preferences.dart';
import '../utils/request_names.dart';
import '../utils/requester.dart';
import '../utils/resolution_presets.dart';

class Variables {
  static void Function()? onChanged;
  static void Function(String)? onError;
  static void Function(int)? onPortChanged;

  static bool isMicOn = false;
  static bool hasTorch = true;
  static bool isTorchOn = false;

  static int? framerate;
  static String? resolution;

  static int? cameraId;
  static List<CameraDeviceInfo>? cameras;

  static List<int> fpsRange = [5, 10, 15, 20, 25, 30];
  static Map<ResolutionPreset, List<Resolution>>? resolutionPresets;

  static List<int> getFpsRange(int maxFps) {
    List<int> fpsRange = [];
    for (int i = 5; i <= maxFps; i += 5) {
      fpsRange.add(i);
    }
    return fpsRange;
  }

  static void setupUpdateCallbacks() {
    ConnectionManager.remoteStream.listen((_) async {
      isMicOn = await Requester.getIsMicOn() ?? isMicOn;
      isTorchOn = await Requester.getIsTorchOn() ?? isTorchOn;
      resolution = await Requester.getResolution();

      final maxFps = await Requester.getMaxFramerate();
      if (maxFps != null && maxFps != fpsRange.last) {
        fpsRange = getFpsRange(maxFps);
      }

      framerate = await Requester.getFramerate();
      if (framerate != null && !fpsRange.contains(framerate)) {
        onError?.call("Received invalid framerate: $framerate");
        framerate = null;
      }

      final camerasInfo = await Requester.getCameras();
      if (camerasInfo != null) {
        try {
          cameras = deserializeCamerasInfo(camerasInfo);
        } catch (e) {
          onError?.call(e.toString());
        }
      }

      cameraId = await Requester.getCameraId();
      if (cameraId != null && cameras != null) {
        if (!cameras!.any((camera) => camera.deviceId == cameraId)) {
          onError?.call("Received invalid cameraId: $cameraId");
          cameraId = null;
        }
      }

      hasTorch = await Requester.getHasTorch() ?? hasTorch;
      onChanged?.call(); // inform the variable value change.
    });

    Requester.onUpdateRequest = (request) {
      request.forEach((name, value) async {
        switch (name) {
          case RequestName.port:
            final result = _cast<int>(name, value);
            if (result == null) return;
            if (!await Preferences.setPort(result)) {
              onError?.call("Failed to save preference: port");
            }
            onPortChanged?.call(result);
            break;

          case RequestName.hasTorch:
            final result = _cast<bool>(name, value);
            if (result == null) return;
            hasTorch = result;
            break;

          case RequestName.torch:
            final result = _cast<bool>(name, value);
            if (result == null) return;
            isTorchOn = result;
            break;

          case RequestName.microphone:
            final result = _cast<bool>(name, value);
            if (result == null) return;
            isMicOn = result;
            break;

          case RequestName.resolution:
            final result = _cast<String>(name, value);
            if (result == null) return;
            resolution = result;
            break;

          case RequestName.framerate:
            final result = _cast<int>(name, value);
            if (result == null) return;
            if (fpsRange.contains(result)) {
              framerate = result;
            } else {
              onError?.call("Received invalid framerate: $result");
            }
            break;

          case RequestName.maxFramerate:
            final result = _cast<int>(name, value);
            if (result == null) return;
            if (result >= 5) {
              fpsRange = getFpsRange(result);
            } else {
              onError?.call("Received invalid max-framerate: $result");
            }
            break;

          case RequestName.cameraId:
            final result = _cast<int>(name, value);
            if (result == null) return;
            if (cameras?.any((e) => e.deviceId == result) ?? false) {
              cameraId = result;
            } else {
              onError?.call("Received invalid cameraId: $result");
            }
            break;

          default:
            onError?.call("Received invalid set-update request: $request");
            break;
        }
      });

      onChanged?.call(); // inform the variable value change.
    };
  }

  static T? _cast<T>(String name, dynamic value) {
    if (value is T) {
      return value;
    }
    onError?.call("Received invalid set-update value: {$name: $value}");
    return null; // Indicates received invalid type, value should be discarded.
  }
}
