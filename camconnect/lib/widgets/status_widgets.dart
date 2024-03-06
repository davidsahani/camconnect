import 'package:flutter/material.dart';

import 'rotating_widget.dart';

class StartConnectionWidget extends StatelessWidget {
  const StartConnectionWidget({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Start the connection",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15.0,
              color: Colors.blueGrey,
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(width: 6.5),
          Icon(
            Icons.wifi,
            size: 18.0,
            color: Colors.grey,
          )
        ],
      ),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: onStart,
        child: const Text("Start"),
      ),
    ]);
  }
}

class WaitingConnectionWidget extends StatelessWidget {
  const WaitingConnectionWidget({super.key, required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Waiting for connection",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15.0,
              color: Colors.blueGrey,
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(width: 6.5),
          RotatingWidget(
            child: Icon(
              Icons.data_usage,
              size: 18.0,
              color: Colors.blue,
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: onCancel,
        child: const Text("Cancel"),
      ),
    ]);
  }
}

class ConnectedConnectionWidget extends StatelessWidget {
  const ConnectedConnectionWidget({
    super.key,
    required this.address,
    required this.onClose,
  });

  final String address;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Remote Device Connected",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15.0,
                color: Colors.blueGrey,
                fontFamily: 'Montserrat',
              ),
            ),
            SizedBox(width: 6.5),
            Icon(
              Icons.wifi,
              size: 18.0,
              color: Colors.blue,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text("IP: $address"),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onClose,
          child: const Text("Close"),
        )
      ],
    );
  }
}

class NotConnectedWidget extends StatelessWidget {
  const NotConnectedWidget({super.key, required this.onRecheck});

  final VoidCallback onRecheck;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Not Connected to network",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15.0,
                color: Colors.blueGrey,
                fontFamily: 'Montserrat',
              ),
            ),
            SizedBox(width: 6.5),
            Icon(
              Icons.wifi_off,
              size: 18.0,
              color: Colors.blue,
            ),
          ],
        ),
        const SizedBox(height: 15.0),
        const Text(
          "Ensure your device is connected to Wi-Fi or the same network as your remote device.",
          style: TextStyle(
            color: Colors.red,
            fontSize: 15.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10.0),
        ElevatedButton(
          onPressed: onRecheck,
          child: const Text("Recheck"),
        ),
      ],
    );
  }
}

class ConnectionErrorWidget extends StatelessWidget {
  const ConnectionErrorWidget({
    super.key,
    required this.errorMsg,
    required this.onRetry,
  });

  final String errorMsg;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning,
              size: 20.0,
              color: Color.fromARGB(255, 252, 215, 4),
            ),
            SizedBox(width: 6.5),
            Text(
              "Connection Error",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15.0,
                color: Colors.blueGrey,
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          errorMsg,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onRetry,
          child: const Text("Retry"),
        ),
      ],
    );
  }
}
