import 'package:flutter/material.dart';

import '../utils/connection_manager.dart';
import '../utils/preferences.dart';
import '../utils/requester.dart';
import '../utils/task_executer.dart';
import '../widgets/editable_text_box.dart';
import '../widgets/snack_bars.dart';
import '../widgets/status_widgets.dart';
import 'connection_variables.dart';

class ConnectionWidget extends StatefulWidget {
  const ConnectionWidget({super.key});

  @override
  State<ConnectionWidget> createState() => _ConnectionWidgetState();
}

class _ConnectionWidgetState extends State<ConnectionWidget> {
  int _port = ConnectionManager.port;
  String _ipAddress = ConnectionManager.remoteAddress;
  var _connectionStatus = ConnectionManager.connectionStatus;

  @override
  void initState() {
    super.initState();

    ConnectionManager.onIPChanged = (address) {
      if (_connectionStatus != ConnectionStatus.waiting) {
        setSafeState(() => _ipAddress = address ?? "");
      } else {
        setSafeState(() {
          _ipAddress = address ?? ConnectionManager.remoteAddress;
        });
      }
    };
    Variables.onPortChanged = (port) {
      setSafeState(() => _port = port);
    };
    ConnectionManager.statusStream.listen((connectionStatus) {
      setSafeState(() => _connectionStatus = connectionStatus);
    });
  }

  void setSafeState(VoidCallback callback) {
    if (mounted) setState(callback);
  }

  String? _validateIPv4(String text) {
    if (text.isEmpty) {
      return null; // it'll cause empty string tbr,
      // Handle empty string returned on onSubmitted.
    }
    final parts = text.split('.');
    if (parts.length != 4) {
      return "Invalid IPv4 address format.";
    }
    for (final part in parts) {
      final number = int.tryParse(part);
      if (number == null || number < 0 || number > 255) {
        return "Invalid IPv4 address format.";
      }
    }
    return null; // indicates no error.
  }

  String? _validatePort(String text) {
    if (text.isEmpty) {
      return "Field cannot be empty.";
    }
    if (text.startsWith('0') && text != '0') {
      return "Port cannot start with a leading zero.";
    }
    final portNumber = int.tryParse(text);
    if (portNumber == null) {
      return "Port must be a number.";
    }
    if (!(portNumber >= 1024 && portNumber <= 65535)) {
      return "Port must be in range (1024-65535).";
    }
    return null; // indicates no error.
  }

  void _onPortSubmitted(String text) async {
    final port = int.parse(text);

    if (!await Preferences.setPort(port)) {
      _showSnackBar("Failed to save preference: port -> $port");
    }
    if (!ConnectionManager.isConnected) {
      return _showSnackBar("Port number must also be changed on remote end.");
    }
    if (!(await Requester.setPort(port))) {
      _showSnackBar(
        duration: const Duration(seconds: 5),
        "Could not change port number on remote end, it must be changed there.",
      );
    }
    await ConnectionManager.reconnect();
  }

  void _toggleNetworkDiscovery({bool? enable}) {
    final value = enable ?? !ConnectionManager.networkDiscoveryEnabled;
    TaskExecuter.run(taskId: 1807, () async {
      setSafeState(() => ConnectionManager.networkDiscoveryEnabled = value);

      if (value) {
        await ConnectionManager.reconnect();
      } else {
        await ConnectionManager.disconnect();
      }
    });
  }

  void _showSnackBar(String message,
          {Duration duration = const Duration(seconds: 3)}) =>
      showSnackBarMessage(context, message, duration: duration);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 350,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(25, 25, 25, 10),
          child: Column(children: [
            EditableTextBox(
              prefixText: "IP: ",
              text: _ipAddress,
              hintText: _connectionStatus != ConnectionStatus.waiting
                  ? "Enter remote address."
                  : "Discovering remote address...",
              errorChecker: _validateIPv4,
              onSubmitted: (addr) {
                if (addr.isEmpty) return;
                ConnectionManager.reconnect(addr: addr);
              },
              onChanged: (value) => _ipAddress = value,
            ),
            const SizedBox(height: 5),
            EditableTextBox(
              prefixText: "Port: ",
              text: _port.toString(),
              errorChecker: _validatePort,
              onSubmitted: _onPortSubmitted,
            ),
            const SizedBox(height: 10.0),
            InkWell(
              onTap: _toggleNetworkDiscovery,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(3.0, 3.0, 0.0, 3.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Automatic Network Discovery",
                      style: TextStyle(fontSize: 16.0),
                    ),
                    Transform.scale(
                      scale: 0.65,
                      child: Switch(
                        onChanged: (value) {
                          _toggleNetworkDiscovery(enable: value);
                        },
                        value: ConnectionManager.networkDiscoveryEnabled,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
                height: (ConnectionManager.errorMsg.length > 30) ? 15 : 25),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: const EdgeInsets.all(16.0),
              child: _getStatusWidget(_connectionStatus, () {
                final errorMsg = _validateIPv4(_ipAddress);
                if (errorMsg == null) {
                  ConnectionManager.connect(addr: _ipAddress);
                } else {
                  _showSnackBar(
                    errorMsg.isNotEmpty ? errorMsg : "Enter remote address.",
                  );
                }
              }),
            ),
          ]),
        ),
      ),
    );
  }
}

Widget _getStatusWidget(
    ConnectionStatus connectionStatus, VoidCallback onConnect) {
  switch (connectionStatus) {
    case ConnectionStatus.disconnected:
      if (!ConnectionManager.networkDiscoveryEnabled) {
        return ConnectRemoteWidget(onConnect: onConnect);
      }
      return const StartConnectionWidget(
        onStart: ConnectionManager.connect,
      );
    case ConnectionStatus.connecting:
      return const ConnectingRemoteWidget(
        onCancel: ConnectionManager.disconnect,
      );
    case ConnectionStatus.waiting:
      return const WaitingConnectionWidget(
        onCancel: ConnectionManager.disconnect,
      );
    case ConnectionStatus.connected:
      return const ConnectedConnectionWidget(
        onClose: ConnectionManager.disconnect,
      );
    default:
      return ConnectionErrorWidget(
        errorMsg: ConnectionManager.errorMsg,
        onRetry: () async {
          if (ConnectionManager.networkDiscoveryEnabled) {
            await ConnectionManager.reconnect();
          } else {
            await ConnectionManager.disconnect();
            onConnect(); // delegate it for text-box IP address.
          }
        },
      );
  }
}

// #=================== Show/Hide Connection Window ===================# //

OverlayEntry? _connectionWindowOverlayEntry;

void showConnectionWindow(BuildContext context) {
  if (_connectionWindowOverlayEntry != null) return;

  _connectionWindowOverlayEntry = OverlayEntry(
    builder: (context) => Stack(
      children: [
        GestureDetector(
          // Remove when tapped outside
          onTap: hideConnectionWindow,
        ),
        SimpleDialog(
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          surfaceTintColor: Colors.blue.shade50,
          children: const [ConnectionWidget()],
        ),
      ],
    ),
  );

  Overlay.of(context).insert(_connectionWindowOverlayEntry!);
}

void hideConnectionWindow() {
  if (_connectionWindowOverlayEntry != null) {
    _connectionWindowOverlayEntry!.remove();
    _connectionWindowOverlayEntry = null;
  }
}
