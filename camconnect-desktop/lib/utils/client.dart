import 'dart:convert';
import 'dart:io';

import 'signaling.dart';

class Client {
  void Function()? onConnected;
  void Function()? onDisconnected;
  void Function(String)? onError;
  void Function(String)? onSoftError;

  void Function(Map<String, dynamic>)? onReceivedMessage;

  final signaling = Signaling();

  Client() {
    signaling.onError = onError;
    signaling.onClose = _onClose;
    signaling.onMessageSend = sendMessage;
  }

  WebSocket? _socket;
  bool _intentionalDisconnect = false;

  Future<void> connect(String address, int port) async {
    _socket = await WebSocket.connect('ws://$address:$port');

    await signaling.setupPeerConnection();

    _socket!.listen(
      (data) {
        Map<String, dynamic> message;
        try {
          message = json.decode(data);
        } catch (_) {
          return onSoftError?.call("Error decoding websocket message.");
        }

        if (!message.containsKey("type")) {
          return onReceivedMessage?.call(message);
        }

        // Handle possible remote peer invalid value that may cause type casting error.
        bool status = false; // false -> unknown remote peer signaling message.
        try {
          status = signaling.handleSignalingMessage(message);
        } catch (e) {
          return onSoftError?.call(e.toString());
        }

        if (!status) {
          onSoftError?.call("Unknown signaling message: ${message['type']}");
        }
      },
      onDone: () async {
        try {
          await _socket?.close(); // socket might be open.
          await signaling.close(); // close peer connection.
        } catch (e) {
          onSoftError?.call(e.toString());
        }
        _onClose();
      },
      cancelOnError: true,
      onError: (e) => onError?.call(e.toString()),
    );

    _intentionalDisconnect = false;
    onConnected?.call(); // signal connected.
  }

  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    await _socket?.close();
  }

  void _onClose() {
    if (!_intentionalDisconnect) {
      onDisconnected?.call();
    }
  }

  void sendMessage(Map<String, dynamic> message) {
    try {
      _socket?.add(json.encode(message));
    } catch (e) {
      onSoftError?.call(e.toString());
    }
  }
}
