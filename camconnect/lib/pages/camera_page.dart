import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../utils/connection_manager.dart';
import '../utils/settings_manager.dart';
import '../utils/task_executer.dart';
import '../widgets/snack_bars.dart';
import '../widgets/swap_layout.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  bool _isPortrait = true;
  final _localRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() async {
    await _localRenderer.initialize();

    Variables.onChanged = () {
      if (mounted) setState(() {});
    };

    final stream = await ConnectionManager.signaling.getLocalStream();
    if (stream != null) {
      _setLocalRenderer(stream);
    }

    ConnectionManager.localStream.listen(_setLocalRenderer);
  }

  void _setLocalRenderer(MediaStream stream) {
    if (mounted && _localRenderer.textureId != null) {
      setState(() => _localRenderer.srcObject = stream);
    }
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Stack(children: [
      Container(
        color: Colors.black,
        child: RTCVideoView(_localRenderer),
      ),
      Container(
        alignment: _isPortrait ? Alignment.centerRight : Alignment.bottomCenter,
        padding: const EdgeInsets.all(8.0),
        child: SwapLayout(
          swap: !_isPortrait,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIconButton(
              Icons.cameraswitch,
              () => TaskExecuter.run(taskId: 1320, () async {
                await SettingsManager.switchCamera();
                // hasTorch fails if it's called soon after stream change
                await Future.delayed(const Duration(milliseconds: 800));
                await SettingsManager.getHasTorch(); // sends set-update
              }, onError: (e) => _showSnackBarMessage(e.toString())),
            ),
            _buildIconButton(
              Variables.isMicOn ? Icons.mic : Icons.mic_off,
              () => TaskExecuter.run(
                () async => SettingsManager.setMic(!Variables.isMicOn),
                onError: (e) => _showSnackBarMessage(e.toString()),
              ),
            ),
            _buildIconButton(
              !Variables.hasTorch
                  ? Icons.no_flash
                  : Variables.isTorchOn
                      ? Icons.flash_on
                      : Icons.flash_off,
              () => TaskExecuter.run(
                taskId: 544,
                () => SettingsManager.setTorch(!Variables.isTorchOn),
                onError: (_) => _showSnackBarMessage(
                  "Failed to turn on/off flash try restarting the app.",
                ),
              ), // on/off torch
            )
          ],
        ),
      ),
    ]);
  }

  Widget _buildIconButton(IconData icon, VoidCallback callback) =>
      IconButton(icon: Icon(icon), color: Colors.white, onPressed: callback);

  void _showSnackBarMessage(String message) =>
      showSnackBarMessage(context, message, keepAboveNavBar: _isPortrait);
}
