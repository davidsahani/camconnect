import 'dart:convert';
import 'dart:io';

import 'signaling.dart';

class Server {
  void Function()? onConnected;
  void Function()? onDisconnected;
  void Function(String)? onError;
  void Function(String)? onSoftError;

  void Function(Map<String, dynamic>)? onReceivedMessage;

  InternetAddress? remoteAddress;

  final signaling = Signaling();

  Server() {
    signaling.onError = onError;
    signaling.onClose = _onClose;
    signaling.onMessageSend = sendMessage;
  }

  HttpServer? _server;
  WebSocket? _socket;
  bool _intentionalDisconnect = false;

  Future<void> connect(InternetAddress address, int port) async {
    _server = await HttpServer.bind(address, port);

    _server!.listen(
      (request) async {
        if (!WebSocketTransformer.isUpgradeRequest(request)) {
          request.response
            ..statusCode = HttpStatus.notFound
            ..write('Not Found');
          await request.response.close();
          return;
        }

        remoteAddress = request.connectionInfo?.remoteAddress;
        _socket = await WebSocketTransformer.upgrade(request);

        try {
          await _handleWebSocket(_socket!);
        } catch (e) {
          // socket might not have been closed
          return onError?.call(e.toString());
        }

        onConnected?.call(); // signal client connected.
        await _server?.close(force: true); // serve only one client.
      },
      cancelOnError: true,
      onError: (e) => onError?.call(e.toString()),
    );

    _intentionalDisconnect = false;
  }

  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    await _socket?.close();
    await _server?.close(force: true);
  }

  Future<void> _handleWebSocket(WebSocket webSocket) async {
    await signaling.setupPeerConnection();

    webSocket.listen(
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

    await signaling.addLocalStream();
    await signaling.createOffer(); // send offer
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
