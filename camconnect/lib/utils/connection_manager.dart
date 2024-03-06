import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'broadcaster.dart';
import 'preferences.dart';
import 'request_handler.dart';
import 'server.dart';
import 'signaling.dart';

enum ConnectionStatus {
  notConnected,
  waiting,
  connected,
  disconnected,
  error,
}

class ConnectionManager {
  static int get port => Preferences.getPort();
  static const _broadcastMessage = "camconnect broadcast";

  static bool networkDiscoveryEnabled = true;
  static String errorMsg = "", connectivityErrorMsg = "";
  static StreamSubscription<ConnectivityResult>? _networkChangeListener;

  static InternetAddress? currentAddress;
  static String? get remoteAddress => _server.remoteAddress?.address;
  static ConnectionStatus get connectionStatus => _connectionStatus;
  static Signaling get signaling => _server.signaling;

  static void Function(String?)? onIPChanged;
  static void Function(String)? onError, onConnectivityError;

  static final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();

  static Stream<ConnectionStatus> get statusStream => _statusController.stream;

  static final StreamController<MediaStream> _localStreamController =
      StreamController<MediaStream>.broadcast();

  static Stream<MediaStream> get localStream => _localStreamController.stream;

  static final Server _server = Server();
  static ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;

  static bool get isConnected =>
      _connectionStatus == ConnectionStatus.connected;

  static void init() => _setupCallbacks();

  static Future<void> connect({InternetAddress? addr}) async {
    if (addr == null &&
        (await getNetworkAddresses())
            .any((e) => e.$2.address == currentAddress?.address)) {
      addr = currentAddress; // use current address if valid.
    }

    currentAddress = addr ?? await getWifiIP();
    onIPChanged?.call(currentAddress?.address);

    if (currentAddress == null) {
      final result = await Connectivity().checkConnectivity();
      if (result == ConnectivityResult.none) {
        return _updateStatus(ConnectionStatus.notConnected);
      } else {
        return _updateErrorMsg("Could not obtain ip address.");
      }
    }

    try {
      await _server.connect(currentAddress!, port);
    } catch (e) {
      return _updateErrorMsg(e.toString());
    }

    if (networkDiscoveryEnabled) {
      try {
        await Broadcaster.start(currentAddress!, port, _broadcastMessage);
      } catch (e) {
        onError?.call(e.toString()); // port binding may fail
      }
    }

    _startNetworkChangeListener();
    _updateStatus(ConnectionStatus.waiting);
  }

  static Future<void> disconnect() async {
    Broadcaster.stop();
    await _server.disconnect();
    _updateStatus(ConnectionStatus.disconnected);
  }

  static Future<void> reconnect({InternetAddress? addr}) async {
    await disconnect();
    errorMsg = ""; // reset
    await connect(addr: addr);
  }

  static Future<void> setNetworkDiscoveryEnabled(bool enable) async {
    if (!enable) {
      Broadcaster.stop();
    } else if (currentAddress != null) {
      await Broadcaster.start(currentAddress!, port, _broadcastMessage);
    }
    networkDiscoveryEnabled = enable;
  }

  static void checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (result != ConnectivityResult.none &&
        _connectionStatus == ConnectionStatus.notConnected) {
      _updateStatus(ConnectionStatus.disconnected);
    }
  }

  static void _setupCallbacks() {
    _server.onConnected = () {
      Broadcaster.stop();
      _stopNetworkChangeListener();
      _updateStatus(ConnectionStatus.connected);
    };

    _server.onDisconnected = reconnect;
    _server.onError = _updateErrorMsg;
    _server.onSoftError = onError;

    _server.onReceivedMessage = RequestHandler.handleRequest;
    RequestHandler.onSend = _server.sendMessage;

    _server.signaling.onLocalStream = (stream) {
      _localStreamController.add(stream);
    };

    _startNetworkChangeListener();
  }

  static void _startNetworkChangeListener() {
    _networkChangeListener ??=
        Connectivity().onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.none) {
        onIPChanged?.call(currentAddress = null);
        onConnectivityError?.call(connectivityErrorMsg = "");
        return _updateStatus(ConnectionStatus.notConnected);
      }
      if (_connectionStatus == ConnectionStatus.notConnected) {
        _updateStatus(ConnectionStatus.disconnected);
      }
      if (result != ConnectivityResult.wifi &&
          result != ConnectivityResult.ethernet) {
        final phrase = networkDiscoveryEnabled ? "discover" : "connect with";
        connectivityErrorMsg =
            "Warning: You are connected to a ${result.name} network, "
            "Devices may not be able to $phrase each other on different networks.";

        onConnectivityError?.call(connectivityErrorMsg);
      } else if (connectivityErrorMsg.isNotEmpty) {
        onConnectivityError?.call(connectivityErrorMsg = "");
      }
    }, onError: (error) => onError?.call(error.toString()));
  }

  static Future<void> _stopNetworkChangeListener() async {
    onConnectivityError?.call(connectivityErrorMsg = "");
    await _networkChangeListener?.cancel();
    _networkChangeListener = null;
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
    await _localStreamController.close();
    await _server.signaling.dispose();
  }
}

/// Retrieves the current wifi IP address.
Future<InternetAddress?> getWifiIP() async {
  final addr = await NetworkInfo().getWifiIP();
  if (addr == null) {
    return null; // wifi address is unavailable.
  }
  return InternetAddress(addr, type: InternetAddressType.IPv4);
}

/// Retrieves network addresses for all available network interfaces.
Future<List<(NetworkInterface, InternetAddress)>> getNetworkAddresses() async {
  List<(NetworkInterface, InternetAddress)> addresses = [];

  final interfaces =
      await NetworkInterface.list(type: InternetAddressType.IPv4);

  for (final interface in interfaces) {
    for (final addr in interface.addresses) {
      addresses.add((interface, addr));
    }
  }

  return addresses;
}
