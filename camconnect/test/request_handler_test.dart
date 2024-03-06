import 'package:camconnect/utils/preferences.dart';
import 'package:camconnect/utils/request_handler.dart';
import 'package:camconnect/utils/request_names.dart';
import 'package:camconnect/utils/settings_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  await Preferences.init();

  group("Get Requests", _testGetRequests);
  group("Set Requests", _testSetRequests);

  test("invalid-get-request", () {
    const request = {
      'get-request': {'name': 'value'}
    };
    RequestHandler.onSend = (response) {
      expect(response['invalid-get-request'], request['get-request']);
    };
    RequestHandler.handleRequest(request);
  });

  test("invalid-set-request", () {
    const request = {'set-request': 'name'};

    RequestHandler.onSend = (response) {
      expect(response['invalid-set-request'], request['set-request']);
    };
    RequestHandler.handleRequest(request);
  });

  test("unknown-request", () {
    const request = {'unknown-request': 'name'};

    RequestHandler.onSend = (response) {
      expect(response['unknown-request'], request);
    };
    RequestHandler.handleRequest(request);
  });
}

void _testGetRequests() {
  test("get-request: microphone", () {
    final request = TestRequest(
      RequestName.microphone,
      Variables.isMicOn,
    );

    RequestHandler.onSend = (response) {
      expect(request.getResponseResult(response), request.result);
    };

    RequestHandler.handleRequest(request.getRequest);
  });

  test("get-request: torch", () {
    final request = TestRequest(
      RequestName.torch,
      Variables.isTorchOn,
    );

    RequestHandler.onSend = (response) {
      expect(request.getResponseResult(response), request.result);
    };

    RequestHandler.handleRequest(request.getRequest);
  });

  test("get-request: cameraId", () {
    final request = TestRequest(
      RequestName.cameraId,
      Preferences.getCameraId(),
    );

    RequestHandler.onSend = (response) {
      expect(request.getResponseResult(response), request.result);
    };

    RequestHandler.handleRequest(request.getRequest);
  });

  test("get-request: framerate", () {
    final request = TestRequest(
      RequestName.framerate,
      Preferences.getFps(),
    );

    RequestHandler.onSend = (response) {
      expect(request.getResponseResult(response), request.result);
    };

    RequestHandler.handleRequest(request.getRequest);
  });

  test("get-request: maxFramerate", () {
    final request = TestRequest(
      RequestName.maxFramerate,
      Preferences.getMaxFps(),
    );

    RequestHandler.onSend = (response) {
      expect(request.getResponseResult(response), request.result);
    };

    RequestHandler.handleRequest(request.getRequest);
  });

  test("get-request: orientation", () {
    final request = TestRequest(
      RequestName.orientation,
      Preferences.getOrientation(),
    );

    RequestHandler.onSend = (response) {
      expect(request.getResponseResult(response), request.result);
    };

    RequestHandler.handleRequest(request.getRequest);
  });

  test("get-request: resolution", () {
    final request = TestRequest(
      RequestName.resolution,
      Preferences.getResolution(),
    );

    RequestHandler.onSend = (response) {
      expect(request.getResponseResult(response), request.result);
    };

    RequestHandler.handleRequest(request.getRequest);
  });

  test("unknown-get-request", () {
    const request = TestRequest(
      "unknown",
      "value",
    );

    RequestHandler.onSend = (response) {
      expect(response['unknown-get-request'], request.name);
    };

    RequestHandler.handleRequest(request.getRequest);
  });
}

void _testSetRequests() {
  test("set-request: port", () {
    const request = TestRequest(RequestName.port, 8080);

    RequestHandler.onSend = (response) {
      expect(request.setResponseResult(response), isTrue);
    };

    RequestHandler.handleRequest(request.setRequest);
  });

  test("set-request: framerate", () {
    const request = TestRequest(RequestName.framerate, 30);

    RequestHandler.onSend = (response) {
      expect(request.setResponseResult(response), isTrue);
    };

    RequestHandler.handleRequest(request.setRequest);
  });

  test("set-request: maxFramerate", () {
    const request = TestRequest(RequestName.maxFramerate, 30);

    RequestHandler.onSend = (response) {
      expect(request.setResponseResult(response), isTrue);
    };

    RequestHandler.handleRequest(request.setRequest);
  });

  test("set-request: resolution", () {
    const request = TestRequest(RequestName.resolution, '1280x720');

    RequestHandler.onSend = (response) {
      expect(request.setResponseResult(response), isTrue);
    };

    RequestHandler.handleRequest(request.setRequest);
  });

  test("set-request: microphone", () {
    const request = TestRequest(RequestName.microphone, false);

    RequestHandler.onSend = (response) {
      expect(request.setResponseResult(response), isFalse);
    };

    RequestHandler.handleRequest(request.setRequest);
  });

  test("unknown-set-request", () {
    const request = TestRequest(
      "unknown",
      "value",
    );

    RequestHandler.onSend = (response) {
      expect(response['unknown-set-request'], {request.name: request.result});
    };

    RequestHandler.handleRequest(request.setRequest);
  });
}

class TestRequest {
  final String name;
  final dynamic result;

  const TestRequest(
    this.name,
    this.result,
  );

  Map<String, String> get getRequest {
    return {'get-request': name};
  }

  Map<String, Map<String, dynamic>> get setRequest {
    return {
      'set-request': {name: result}
    };
  }

  dynamic getResponseResult(Map<String, dynamic> response) {
    return response['get-response'][name]['result'];
  }

  bool setResponseResult(Map<String, dynamic> response) {
    return response['set-response'][name]['result'] == 'success';
  }
}
