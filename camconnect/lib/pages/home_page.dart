import 'dart:io';

import 'package:flutter/material.dart';

import '../utils/connection_manager.dart';
import '../utils/settings_manager.dart';
import '../utils/task_executer.dart';
import '../widgets/ip_dropdown_dialog.dart';
import '../widgets/snack_bars.dart';
import '../widgets/status_widgets.dart';
import '../widgets/text_boxes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _port = ConnectionManager.port;
  String? _ipAddress = ConnectionManager.currentAddress?.address;
  String _connectivityErrorMsg = ConnectionManager.connectivityErrorMsg;
  ConnectionStatus _connectionStatus = ConnectionManager.connectionStatus;

  @override
  void initState() {
    super.initState();

    SettingsManager.onPortChanged = (port) {
      setSafeState(() => _port = port);
    };
    ConnectionManager.onIPChanged = (address) {
      setSafeState(() => _ipAddress = address);
    };
    ConnectionManager.statusStream.listen((connectionStatus) {
      setSafeState(() => _connectionStatus = connectionStatus);
    });
    ConnectionManager.onConnectivityError = (errorMsg) {
      setSafeState(() => _connectivityErrorMsg = errorMsg);
    };
  }

  void setSafeState(VoidCallback callback) {
    if (mounted) setState(callback);
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
    await SettingsManager.setPort(int.parse(text));

    if (!ConnectionManager.isConnected) {
      _showSnackBarMessage(
        duration: const Duration(seconds: 5),
        "Port number must also be changed on remote end.",
      );
    }
    await ConnectionManager.reconnect();
  }

  void _toggleNetworkDiscovery({bool? enable}) {
    TaskExecuter.run(taskId: 78, () async {
      await ConnectionManager.setNetworkDiscoveryEnabled(
          enable ?? !ConnectionManager.networkDiscoveryEnabled);
      setSafeState(() => ConnectionManager.networkDiscoveryEnabled);
    }, onError: (e) => _showSnackBarMessage(e.toString()));
  }

  void _showSnackBarMessage(String msg,
          {Duration duration = const Duration(seconds: 2)}) =>
      showSnackBarMessage(context, msg, duration: duration);

  @override
  Widget build(BuildContext context) {
    bool isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final double topPadding = isPortrait ? 20.0 : 0.0;

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.0, topPadding, 20.0, 0.0),
        child: Column(children: [
          TextBox(
            prefixText: "IP: ",
            text: _ipAddress ?? "Null",
            onPressed: () async {
              final addresses = await getNetworkAddresses();
              _showIpDropdownEntriesDialog(addresses);
            },
          ),
          const SizedBox(height: 5.0),
          EditableTextBox(
            prefixText: "Port: ",
            text: _port.toString(),
            errorChecker: _validatePort,
            onSubmitted: _onPortSubmitted,
          ),
          SizedBox(height: isPortrait ? 10.0 : 5.0),
          InkWell(
            onTap: _toggleNetworkDiscovery,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5.0, vertical: 3.0),
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
          SizedBox(height: isPortrait ? 15.0 : 5.0),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.all(16.0),
            child: _getStatusWidget(_connectionStatus),
          ),
          Visibility(
            visible: _connectivityErrorMsg.isNotEmpty,
            child: Column(children: [
              const SizedBox(height: 15.0),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.all(10.0),
                child: Row(children: [
                  const Icon(
                    Icons.warning,
                    color: Color.fromARGB(255, 238, 210, 2),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(child: Text(_connectivityErrorMsg)),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  void _showIpDropdownEntriesDialog(
      List<(NetworkInterface, InternetAddress)> addresses) {
    showIpDropdownEntriesDialog(context, addresses, (addr) {
      ConnectionManager.reconnect(addr: addr.$2);
    });
  }
}

Widget _getStatusWidget(ConnectionStatus connectionStatus) {
  switch (connectionStatus) {
    case ConnectionStatus.disconnected:
      return const StartConnectionWidget(
        onStart: ConnectionManager.connect,
      );
    case ConnectionStatus.waiting:
      return const WaitingConnectionWidget(
        onCancel: ConnectionManager.disconnect,
      );
    case ConnectionStatus.connected:
      return ConnectedConnectionWidget(
        address: ConnectionManager.remoteAddress ??
            "Address could not be obtained.", //
        onClose: ConnectionManager.disconnect,
      );
    case ConnectionStatus.error:
      return ConnectionErrorWidget(
        errorMsg: ConnectionManager.errorMsg,
        onRetry: ConnectionManager.reconnect,
      );
    default:
      return const NotConnectedWidget(
        onRecheck: ConnectionManager.checkConnectivity,
      );
  }
}
