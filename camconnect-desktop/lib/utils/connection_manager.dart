import 'dart:async';
import 'dart:io';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'broadcast_listener.dart';
import 'client.dart';
import 'preferences.dart';
import 'requester.dart';
import 'signaling.dart';

enum ConnectionStatus {
  waiting,
  connecting,
  disconnected,
  connected,
  error,
}

class ConnectionManager {
  static int get port => Preferences.getPort();
  static const _broadcastMessage = "camconnect broadcast";

  static bool networkDiscoveryEnabled = true;
  static String remoteAddress = "", errorMsg = "";

  static ConnectionStatus get connectionStatus => _connectionStatus;
  static Signaling get signaling => _client.signaling;

  static final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();

  static Stream<ConnectionStatus> get statusStream => _statusController.stream;

  static final StreamController<MediaStream> _remoteStreamController =
      StreamController<MediaStream>.broadcast();

  static Stream<MediaStream> get remoteStream => _remoteStreamController.stream;

  static void Function(String?)? onIPChanged;
  static void Function(String)? onError;

  static final Client _client = Client();
  static ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;

  static bool get isConnected =>
      _connectionStatus == ConnectionStatus.connected;

  static void init() => _setupCallbacks();

  static Future<void> connect({String? addr}) async {
    onIPChanged?.call(addr);

    if (addr != null) {
      remoteAddress = addr;
      _updateStatus(ConnectionStatus.connecting);
      try {
        await _client.connect(addr, port);
      } catch (e) {
        _updateErrorMsg(e.toString());
      }
      return;
    }

    try {
      await BroadcastListener.start(InternetAddress.anyIPv4, port);
    } catch (e) {
      _updateErrorMsg(e.toString()); // port binding may fail
    }
    _updateStatus(ConnectionStatus.waiting);
  }

  static Future<void> disconnect() async {
    BroadcastListener.stop();
    await _client.disconnect();
    _updateStatus(ConnectionStatus.disconnected);
  }

  static Future<void> reconnect({String? addr}) async {
    await disconnect();
    errorMsg = ""; // reset
    if (addr?.isNotEmpty ?? networkDiscoveryEnabled) {
      await connect(addr: addr);
    } else {
      await connect(addr: remoteAddress.isNotEmpty ? remoteAddress : addr);
    }
  }

  static void _setupCallbacks() {
    BroadcastListener.onBroadcast = (ip, msg) async {
      if (msg != _broadcastMessage) {
        return; // not a camconnect broadcast.
      }
      BroadcastListener.stop();

      remoteAddress = ip.address;
      try {
        await _client.connect(ip.address, port);
      } catch (e) {
        _updateErrorMsg(e.toString());
      }
    };

    _client.onConnected = () {
      _updateStatus(ConnectionStatus.connected);
    };

    _client.onDisconnected = reconnect;
    _client.onError = _updateErrorMsg;
    _client.onSoftError = onError;
    BroadcastListener.onError = _updateErrorMsg;

    _client.onReceivedMessage = Requester.handleResponse;
    Requester.onSend = _client.sendMessage;

    _client.signaling.onRemoteStream = (stream) {
      _remoteStreamController.add(stream);
    };
  }

  static void _updateErrorMsg(String msg) {
    errorMsg = msg;
    _updateStatus(ConnectionStatus.error);
  }

  static void _updateStatus(ConnectionStatus status) {
    _connectionStatus = status;
    _statusController.add(status);
  }

  static Future<void> dispose() async {
    await _statusController.close();
    await _remoteStreamController.close();
    await _client.signaling.dispose();
  }
}
