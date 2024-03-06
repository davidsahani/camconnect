import 'dart:io';

class BroadcastListener {
  static void Function(String)? onError;
  static void Function(InternetAddress, String)? onBroadcast;

  static bool get isActive => _udpSocket != null;

  static RawDatagramSocket? _udpSocket;

  static Future<void> start(InternetAddress address, int port) async {
    _udpSocket = await RawDatagramSocket.bind(
      address,
      port,
    );
    _udpSocket!.listen(
      (RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _udpSocket?.receive();
          if (datagram != null) {
            final msg = String.fromCharCodes(datagram.data);
            onBroadcast?.call(datagram.address, msg);
          }
        }
      },
      cancelOnError: true,
      onError: (error) => onError?.call(error.toString()),
    );
  }

  static void stop() {
    _udpSocket?.close();
    _udpSocket = null;
  }
}
