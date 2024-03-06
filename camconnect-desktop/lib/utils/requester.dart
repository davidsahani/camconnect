import 'dart:async';

import 'request_names.dart';

class Requester {
  static void Function(Map<String, dynamic>)? onSend;
  static void Function(Map<String, dynamic>)? onUpdateRequest;
  static void Function(String)? onError;

  static final Map<String, Completer<Map<String, dynamic>>> _completers = {};

  static void handleResponse(Map<String, dynamic> response) {
    response.forEach((name, value) {
      if ((value is! Map<String, dynamic>) || value.keys.isEmpty) {
        return onError?.call(response.toString());
      }

      switch (name) {
        case 'get-response':
          var completer = _completers.remove(value.keys.first);
          completer?.complete(value);
          break;
        case 'set-response':
          var completer = _completers.remove(value.keys.first);
          completer?.complete(value);
          break;
        case 'set-update':
          onUpdateRequest?.call(value);
          break;
        default:
          onError?.call(response.toString());
          break;
      }
    });
  }

  static Future<List<dynamic>?> getCameras() {
    return _getRequest<List<dynamic>>(RequestName.cameras);
  }

  static Future<int?> getCameraId() {
    return _getRequest<int>(RequestName.cameraId);
  }

  static Future<bool?> getIsMicOn() {
    return _getRequest<bool>(RequestName.microphone);
  }

  static Future<bool?> getIsTorchOn() {
    return _getRequest<bool>(RequestName.torch);
  }

  static Future<bool?> getHasTorch() {
    return _getRequest<bool>(RequestName.hasTorch);
  }

  static Future<int?> getFramerate() {
    return _getRequest<int>(RequestName.framerate);
  }

  static Future<int?> getMaxFramerate() {
    return _getRequest<int>(RequestName.maxFramerate);
  }

  static Future<String?> getResolution() {
    return _getRequest<String>(RequestName.resolution);
  }

  static Future<Map<String, dynamic>?> getResolutionPresets() {
    return _getRequest<Map<String, dynamic>>(RequestName.resolutionPresets);
  }

  static Future<bool> switchCamera() {
    return _setRequest(RequestName.switchCamera, null);
  }

  static Future<bool> setCameraId(int cameraId) {
    return _setRequest(RequestName.cameraId, cameraId);
  }

  static Future<bool> setPort(int port) {
    return _setRequest(RequestName.port, port);
  }

  static Future<bool> setMic(bool value) {
    return _setRequest(RequestName.microphone, value);
  }

  static Future<bool> setTorch(bool value) {
    return _setRequest(RequestName.torch, value);
  }

  static Future<bool> setFramerate(int framerate) {
    return _setRequest(RequestName.framerate, framerate);
  }

  static Future<bool> setMaxFramerate(int framerate) {
    return _setRequest(RequestName.maxFramerate, framerate);
  }

  static Future<bool> setResolution(String resolution) {
    return _setRequest(RequestName.resolution, resolution);
  }

  static Future<T?> _getRequest<T>(String name) async {
    onSend?.call({'get-request': name});

    final Map<String, dynamic> response;
    try {
      response = await _fetchResponse(name, 'get');
    } catch (e) {
      onError?.call(e.toString());
      return null;
    }

    if (response.containsKey('result')) {
      final result = response['result'];
      if (result is T) {
        return result;
      }
      onError?.call("Received invalid-value: {$name: $result}");
      return null;
    }

    if (response.containsKey('error')) {
      final error = response['error'];
      onError?.call(error.toString());
    } else {
      onError?.call("Received invalid-response: $response");
    }

    return null; // Indicates either failed or received invalid type / response.
  }

  static Future<bool> _setRequest(String name, dynamic value) async {
    onSend?.call({
      'set-request': {name: value}
    });

    final Map<String, dynamic> response;
    try {
      response = await _fetchResponse(name, 'set');
    } catch (e) {
      onError?.call(e.toString());
      return false;
    }

    if (!response.containsKey('result')) {
      onError?.call("Received invalid-response: $response");
      return false;
    }

    if (response.containsKey('error')) {
      final error = response['error'];
      onError?.call(error.toString());
    }

    return response['result'] == 'success';
  }

  static Future<dynamic> _fetchResponse(
      String requestName, String requestType) async {
    var completer = Completer<Map<String, dynamic>>();
    _completers[requestName] = completer;

    // Set a timeout for the request
    Timer(const Duration(milliseconds: 600), () {
      if (!completer.isCompleted) {
        completer
            .completeError("$requestType-$requestName: request timeout out");
        _completers.remove(requestName);
      }
    });

    return (await completer.future)[requestName];
  }
}
