import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'comps/connection_panel.dart';
import 'utils/connection_manager.dart';
import 'utils/preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Preferences.init();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(202, 6, 113, 235),
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: SafeArea(
          child: Container(
            color: Colors.black,
            child: const CaptureScreen(),
          ),
        ),
        bottomNavigationBar: const ConnectionPanel(),
      ),
    );
  }
}

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    _initialize();
    super.initState();
  }

  void _initialize() async {
    await _remoteRenderer.initialize();
    ConnectionManager.remoteStream.listen((stream) {
      setState(() => _remoteRenderer.srcObject = stream);
    });
    ConnectionManager.init();
    ConnectionManager.connect();
  }

  @override
  void dispose() {
    super.dispose();
    _remoteRenderer.dispose();
    ConnectionManager.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _remoteRenderer.srcObject != null
        ? RTCVideoView(_remoteRenderer)
        : const Center(
            child: CircularProgressIndicator(),
          );
  }
}
