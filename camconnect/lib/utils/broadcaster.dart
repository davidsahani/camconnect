import 'dart:async';
import 'dart:io';

class Broadcaster {
  static const Duration broadcastFrequency = Duration(milliseconds: 1600);

  static bool get isActive => _timer?.isActive ?? false;

  static Timer? _timer;
  static RawDatagramSocket? _udpSocket;

  static Future<void> start(InternetAddress address, int broadcastPort,
      String broadcastMessage) async {
    _udpSocket = await RawDatagramSocket.bind(
      address,
      0, // Let the system choose a free port
    );
    _udpSocket!.broadcastEnabled = true;
    _timer = Timer.periodic(broadcastFrequency, (timer) {
      _udpSocket!.send(
        broadcastMessage.codeUnits,
        InternetAddress('255.255.255.255'), // Broadcast address
        broadcastPort, // The broadcast port
      );
    });
  }

  static void stop() {
    _timer?.cancel();
    _udpSocket?.close();
  }
}
