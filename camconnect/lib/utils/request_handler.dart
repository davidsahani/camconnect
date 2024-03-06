import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'preferences.dart';
import 'request_names.dart';
import 'settings_manager.dart';

class RequestHandler {
  static void Function(Map<String, dynamic>)? onSend;

  static final List<String> _requestsBeingServed = [];

  static void handleRequest(Map<String, dynamic> request) {
    if (request.containsKey('get-request')) {
      try {
        _handleGetRequest(request['get-request']);
      } catch (_) {
        onSend?.call({'invalid-get-request': request['get-request']});
      }
    } else if (request.containsKey('set-request')) {
      try {
        request['set-request'].forEach((name, value) async {
          _requestsBeingServed.add(name);
          await _handleSetRequest(name, value);
          _requestsBeingServed.remove(name);
        });
      } catch (_) {
        onSend?.call({'invalid-set-request': request['set-request']});
      }
    } else {
      onSend?.call({'unknown-request': request});
    }
  }

  static void sendUpdate(String name, dynamic value) {
    if (_requestsBeingServed.contains(name)) {
      return; // currently serving set-request
      // No need to send set-update request
    }
    onSend?.call({
      'set-update': {name: value}
    });
  }

  static void _handleGetRequest(String name) {
    void sendResponse(Future<dynamic> Function() callback) async {
      final Map<String, dynamic> response = {};
      try {
        response['result'] = await callback();
      } catch (e) {
        response['error'] = e.toString();
      }
      onSend?.call({
        'get-response': {name: response}
      });
    }

    switch (name) {
      case RequestName.microphone:
        sendResponse(() async => Variables.isMicOn);
        break;
      case RequestName.torch:
        sendResponse(() async => Variables.isTorchOn);
        break;
      case RequestName.hasTorch:
        sendResponse(() => SettingsManager.getHasTorch());
        break;
      case RequestName.cameraId:
        sendResponse(() async => Preferences.getCameraId());
        break;
      case RequestName.cameras:
        sendResponse(() => SettingsManager.getCameras());
        break;
      case RequestName.framerate:
        sendResponse(() async => Preferences.getFps());
        break;
      case RequestName.maxFramerate:
        sendResponse(() async => Preferences.getMaxFps());
        break;
      case RequestName.orientation:
        sendResponse(() async => Preferences.getOrientation());
        break;
      case RequestName.resolution:
        sendResponse(() async => Preferences.getResolution());
        break;
      case RequestName.resolutionPresets:
        sendResponse(() async => _serializeResolutionPresets(
            await SettingsManager.getResolutionPresets()));
        break;
      default:
        onSend?.call({'unknown-get-request': name});
        break;
    }
  }

  static Future<void> _handleSetRequest(String name, dynamic value) async {
    Future<void> sendResponse(AsyncCallback callback) async {
      final Map<String, dynamic> response = {};
      try {
        await callback();
        response['result'] = 'success';
      } catch (e) {
        response['result'] = 'failure';
        response['error'] = e.toString();
      }
      onSend?.call({
        'set-response': {name: response}
      });
    }

    switch (name) {
      case RequestName.port:
        int? port = _cast<int>(name, value);
        if (port == null) return;
        return sendResponse(() => SettingsManager.setPort(port));

      case RequestName.switchCamera:
        return sendResponse(() => SettingsManager.switchCamera());

      case RequestName.cameraId:
        int? cameraId = _cast<int>(name, value);
        if (cameraId == null) return;
        return sendResponse(() => SettingsManager.setCameraId(cameraId));

      case RequestName.torch:
        bool? turnOn = _cast<bool>(name, value);
        if (turnOn == null) return;
        return sendResponse(() => SettingsManager.setTorch(turnOn));

      case RequestName.microphone:
        bool? turnOn = _cast<bool>(name, value);
        if (turnOn == null) return;
        return sendResponse(() async => SettingsManager.setMic(turnOn));

      case RequestName.framerate:
        int? fps = _cast<int>(name, value);
        if (fps == null) return;
        return sendResponse(() => SettingsManager.setFps(fps));

      case RequestName.maxFramerate:
        int? fps = _cast<int>(name, value);
        if (fps == null) return;
        return sendResponse(() => SettingsManager.setMaxFps(fps));

      case RequestName.resolution:
        String? resolution = _cast<String>(name, value);
        if (resolution == null) return;
        return sendResponse(() => SettingsManager.setResolution(resolution));

      case RequestName.orientation:
        String? orientation = _cast<String>(name, value);
        if (orientation == null) return;
        return sendResponse(() => SettingsManager.setOrientation(orientation));

      default:
        return onSend?.call({
          'unknown-set-request': {name: value}
        });
    }
  }

  static T? _cast<T>(String name, dynamic value) {
    if (value is T) {
      return value;
    }
    onSend?.call({
      'set-response': {
        name: {
          'result': 'failure',
          'error': 'invalid-argument: {$name: $value}'
        }
      }
    });
    return null; // Indicates received invalid type, value should be discarded.
  }
}

Map<String, List<Map<String, int>>> _serializeResolutionPresets(
    Map<ResolutionPreset, List<Resolution>> resolutionPresets) {
  final result = <String, List<Map<String, int>>>{};

  resolutionPresets.forEach((preset, resolutions) {
    result[preset.name] = resolutions
        .map((resolution) => {
              'width': resolution.width,
              'height': resolution.height,
              'maxFps': resolution.maxFps
            })
        .toList();
  });

  return result;
}
