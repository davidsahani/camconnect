import 'package:flutter/material.dart';

import 'rotating_widget.dart';

class ConnectRemoteWidget extends StatelessWidget {
  const ConnectRemoteWidget({super.key, required this.onConnect});

  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Connect To Remote",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15.0,
              color: Colors.blueGrey,
              fontFamily: 'Montserrat',
            ),
          ),
          SizedBox(width: 6.5),
          Icon(
            Icons.signal_cellular_alt,
            size: 18.0,
            color: Colors.grey,
          )
        ],
      ),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: onConnect,
        child: const Text("Connect"),
      ),
    ]);
  }
}

class ConnectingRemoteWidget extends StatelessWidget {
  const ConnectingRemoteWidget({super.key, required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Connecting To Remote",
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
    required this.onClose,
  });

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
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: onClose,
          child: const Text("Close"),
        )
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
            Text(
              "Connection Error",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15.0,
                color: Colors.blueGrey,
                fontFamily: 'Montserrat',
              ),
            ),
            SizedBox(width: 6.5),
            Icon(
              Icons.warning,
              size: 18.0,
              color: Colors.blue,
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
