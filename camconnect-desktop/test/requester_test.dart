import 'package:camconnect/utils/request_names.dart';
import 'package:camconnect/utils/requester.dart';
import 'package:camconnect/utils/resolution_presets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("Request Validation", _testResponseValidation);
  group("Get Responses", _testGetResponses);
  group("Set Responses", _testSetResponses);
}

void _testResponseValidation() {
  test('handleResponse succeeds on valid get-response', () {
    // Arrange
    var called = false;
    Requester.onError = (_) => called = true;

    final response = <String, dynamic>{
      'get-response': <String, dynamic>{"result": "test"}
    };

    // Act
    Requester.handleResponse(response);
    // Assert
    expect(called, isFalse);
  });

  test('handleResponse succeeds on valid set-response', () {
    // Arrange
    var called = false;
    Requester.onError = (_) => called = true;

    final response = <String, dynamic>{
      'set-response': <String, dynamic>{"result": true}
    };

    // Act
    Requester.handleResponse(response);
    // Assert
    expect(called, isFalse);
  });

  test('handleResponse calls onUpdateRequest on set-update', () {
    // Arrange
    var called = false;
    Requester.onUpdateRequest = (_) => called = true;

    final response = <String, dynamic>{
      'set-update': <String, dynamic>{"result": true}
    };

    // Act
    Requester.handleResponse(response);
    // Assert
    expect(called, isTrue);
  });

  test('handleResponse calls onError on unknown response', () {
    // Arrange
    var called = false;
    Requester.onError = (_) => called = true;
    final response = <String, dynamic>{
      'unknown': <String, dynamic>{"result": true}
    };

    // Act
    Requester.handleResponse(response);
    // Assert
    expect(called, isTrue);
  });

  test('handleResponse calls onError on unrecognized response', () {
    // Arrange
    var called = false;
    Requester.onError = (_) => called = true;
    final response = <String, dynamic>{'unrecognized': <String>{}};

    // Act
    Requester.handleResponse(response);
    // Assert
    expect(called, isTrue);
  });
}

void _testGetResponses() {
  test('get-response: cameras', () async {
    bool valid = true;
    Requester.onError = (_) => valid = false;

    const response = TestResponse(RequestName.cameras, [
      {'name': 'Back', 'id': '0'},
      {'name': 'Front', 'id': '1'}
    ]);

    // Act
    final futureResult = Requester.getCameras();
    Requester.handleResponse(response.getResponse);
    // check if value is of correct type and can be deserialized.
    try {
      final result = (await futureResult)!;
      deserializeCamerasInfo(result);
      valid = result == response.result;
    } catch (e) {
      valid = false;
    }
    // Assert
    expect(valid, isTrue);
  });

  test('get-response: cameraId', () async {
    const response = TestResponse(RequestName.cameraId, 0);
    // Act
    final futureResult = Requester.getCameraId();
    Requester.handleResponse(response.getResponse);
    // Assert
    expect(await futureResult == response.result, isTrue);
  });

  test('get-response: microphone', () async {
    const response = TestResponse(RequestName.microphone, true);
    // Act
    final futureResult = Requester.getIsMicOn();
    Requester.handleResponse(response.getResponse);
    // Assert
    expect(await futureResult == response.result, isTrue);
  });

  test('get-response: torch', () async {
    const response = TestResponse(RequestName.torch, true);
    // Act
    final futureResult = Requester.getIsTorchOn();
    Requester.handleResponse(response.getResponse);
    // Assert
    expect(await futureResult == response.result, isTrue);
  });

  test('get-response: hasTorch', () async {
    const response = TestResponse(RequestName.hasTorch, true);
    // Act
    final futureResult = Requester.getHasTorch();
    Requester.handleResponse(response.getResponse);
    // Assert
    expect(await futureResult == response.result, isTrue);
  });

  test('get-response: framerate', () async {
    const response = TestResponse(RequestName.framerate, 30);
    // Act
    final futureResult = Requester.getFramerate();
    Requester.handleResponse(response.getResponse);
    // Assert
    expect(await futureResult == response.result, isTrue);
  });

  test('get-response: maxFramerate', () async {
    const response = TestResponse(RequestName.maxFramerate, 30);
    // Act
    final futureResult = Requester.getMaxFramerate();
    Requester.handleResponse(response.getResponse);
    // Assert
    expect(await futureResult == response.result, isTrue);
  });

  test('get-response: resolution', () async {
    const response = TestResponse(RequestName.resolution, '1280x720');
    // Act
    final futureResult = Requester.getResolution();
    Requester.handleResponse(response.getResponse);
    // Assert
    expect(await futureResult == response.result, isTrue);
  });

  test('get-response: resolutionPresets', () async {
    bool valid = true;
    Requester.onError = (_) => valid = false;

    const response = TestResponse(RequestName.resolutionPresets, {
      'low': [
        {'width': 320, 'height': 240, 'maxFps': 30},
        {'width': 192, 'height': 144, 'maxFps': 30},
        {'width': 192, 'height': 108, 'maxFps': 30},
        {'width': 176, 'height': 144, 'maxFps': 30},
        {'width': 160, 'height': 96, 'maxFps': 30}
      ],
      'medium': [
        {'width': 720, 'height': 480, 'maxFps': 30},
        {'width': 640, 'height': 480, 'maxFps': 30},
        {'width': 352, 'height': 288, 'maxFps': 30}
      ],
      'high': [
        {'width': 1280, 'height': 720, 'maxFps': 30},
        {'width': 1080, 'height': 720, 'maxFps': 30},
        {'width': 960, 'height': 720, 'maxFps': 30},
        {'width': 960, 'height': 540, 'maxFps': 30},
        {'width': 800, 'height': 600, 'maxFps': 30},
        {'width': 720, 'height': 720, 'maxFps': 30}
      ],
      'veryHigh': [
        {'width': 1920, 'height': 1080, 'maxFps': 30},
        {'width': 1920, 'height': 886, 'maxFps': 30},
        {'width': 1600, 'height': 720, 'maxFps': 30},
        {'width': 1560, 'height': 720, 'maxFps': 30},
        {'width': 1536, 'height': 720, 'maxFps': 30},
        {'width': 1520, 'height': 720, 'maxFps': 30},
        {'width': 1440, 'height': 1080, 'maxFps': 30},
        {'width': 1440, 'height': 720, 'maxFps': 30},
        {'width': 1404, 'height': 720, 'maxFps': 30},
        {'width': 1280, 'height': 960, 'maxFps': 30},
        {'width': 1280, 'height': 768, 'maxFps': 30},
        {'width': 1024, 'height': 768, 'maxFps': 30}
      ],
      'ultraHigh': [
        {'width': 4160, 'height': 1872, 'maxFps': 30},
        {'width': 4096, 'height': 2304, 'maxFps': 20},
        {'width': 3840, 'height': 2176, 'maxFps': 30},
        {'width': 3840, 'height': 2160, 'maxFps': 30},
        {'width': 3264, 'height': 2448, 'maxFps': 30},
        {'width': 3264, 'height': 1836, 'maxFps': 30},
        {'width': 3264, 'height': 1472, 'maxFps': 30},
        {'width': 2944, 'height': 1656, 'maxFps': 30},
        {'width': 2560, 'height': 1920, 'maxFps': 30},
        {'width': 2560, 'height': 1440, 'maxFps': 30},
        {'width': 2560, 'height': 1280, 'maxFps': 30},
        {'width': 2560, 'height': 1200, 'maxFps': 30},
        {'width': 2280, 'height': 1080, 'maxFps': 30},
        {'width': 2176, 'height': 2176, 'maxFps': 30},
        {'width': 1920, 'height': 1440, 'maxFps': 30},
        {'width': 1920, 'height': 1088, 'maxFps': 30},
        {'width': 1600, 'height': 1200, 'maxFps': 30},
        {'width': 1440, 'height': 1088, 'maxFps': 30}
      ]
    });

    // Act
    final futureResult = Requester.getResolutionPresets();
    Requester.handleResponse(response.getResponse);
    // check if value is of correct type and can be deserialized.
    try {
      final result = (await futureResult)!;
      deserializeResolutionPresets(result);
      valid = result == response.result;
    } catch (e) {
      valid = false;
    }
    // Assert
    expect(valid, isTrue);
  });
}

void _testSetResponses() {
  test('set-response: switchCamera', () async {
    const response = TestResponse(RequestName.switchCamera, null);
    // Act
    final futureResult = Requester.switchCamera();
    Requester.handleResponse(response.setResponse);
    // Assert
    expect(await futureResult, isTrue);
  });

  test('set-response: cameraId', () async {
    const response = TestResponse(RequestName.cameraId, 0);
    // Act
    final futureResult = Requester.setCameraId(response.result);
    Requester.handleResponse(response.setResponse);
    // Assert
    expect(await futureResult, isTrue);
  });

  test('set-response: port', () async {
    const response = TestResponse(RequestName.port, 8080);
    // Act
    final futureResult = Requester.setPort(response.result);
    Requester.handleResponse(response.setResponse);
    // Assert
    expect(await futureResult, isTrue);
  });

  test('set-response: microphone', () async {
    const response = TestResponse(RequestName.microphone, true);
    // Act
    final futureResult = Requester.setMic(response.result);
    Requester.handleResponse(response.setResponse);
    // Assert
    expect(await futureResult, isTrue);
  });

  test('set-response: torch', () async {
    const response = TestResponse(RequestName.torch, true);
    // Act
    final futureResult = Requester.setTorch(response.result);
    Requester.handleResponse(response.setResponse);
    // Assert
    expect(await futureResult, isTrue);
  });

  test('set-response: framerate', () async {
    const response = TestResponse(RequestName.framerate, 30);
    // Act
    final futureResult = Requester.setFramerate(response.result);
    Requester.handleResponse(response.setResponse);
    // Assert
    expect(await futureResult, isTrue);
  });

  test('set-response: maxFramerate', () async {
    const response = TestResponse(RequestName.maxFramerate, 30);
    // Act
    final futureResult = Requester.setMaxFramerate(response.result);
    Requester.handleResponse(response.setResponse);
    // Assert
    expect(await futureResult, isTrue);
  });

  test('set-response: resolution', () async {
    const response = TestResponse(RequestName.resolution, '1280x720');
    // Act
    final futureResult = Requester.setResolution(response.result);
    Requester.handleResponse(response.setResponse);
    // Assert
    expect(await futureResult, isTrue);
  });
}

class TestResponse {
  final String name;
  final dynamic result;

  const TestResponse(
    this.name,
    this.result,
  );

  Map<String, Map<String, Map<String, dynamic>>> get getResponse {
    return {
      'get-response': {
        name: {'result': result}
      }
    };
  }

  Map<String, Map<String, Map<String, dynamic>>> get setResponse {
    return {
      'set-response': {
        name: {'result': 'success'}
      }
    };
  }
}
