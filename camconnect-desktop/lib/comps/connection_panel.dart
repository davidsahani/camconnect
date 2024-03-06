import 'package:flutter/material.dart';

import '../utils/connection_manager.dart';
import '../utils/requester.dart';
import '../utils/resolution_presets.dart';
import '../utils/task_executer.dart';
import '../widgets/conditional_widget.dart';
import '../widgets/resolution_presets_dialog.dart';
import '../widgets/snack_bars.dart';
import 'connection_variables.dart';
import 'connection_widget.dart';
import 'devices_manager.dart';

class ConnectionPanel extends StatefulWidget {
  const ConnectionPanel({Key? key}) : super(key: key);

  @override
  State<ConnectionPanel> createState() => _ConnectionPanelState();
}

class _ConnectionPanelState extends State<ConnectionPanel> {
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _setupCallbacks();
  }

  void _setupCallbacks() {
    ConnectionManager.statusStream.listen((status) async {
      switch (status) {
        case ConnectionStatus.connected:
          setState(() => _isConnected = true);
          hideConnectionWindow();
          break;
        default:
          showConnectionWindow(context);
          if (!_isConnected) return;
          setState(() => _isConnected = false);
          break;
      }
    });

    Requester.onError = _showSnackBar;
    ConnectionManager.onError = _showSnackBar;
    Variables.onError = _showSnackBar;
    Variables.onChanged = () => setState(() {});

    Variables.setupUpdateCallbacks();
    DevicesManager.setupDevices(context);
  }

  void _showSnackBar(String message) => showSnackBarMessage(context, message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.1),
            blurRadius: 30.0,
            offset: const Offset(0.0, 10.0),
          ),
        ],
        borderRadius: BorderRadius.zero,
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Tooltip(
            message: "Switch Camera",
            child: IconButton(
              icon: const Icon(Icons.cameraswitch),
              onPressed: () {
                TaskExecuter.run(taskId: 1320, () async {
                  if (!await Requester.switchCamera()) {
                    return; // on failure.
                  }
                  // hasTorch fails if it's called soon after stream change
                  await Future.delayed(const Duration(milliseconds: 800));
                  final result = await Requester.getHasTorch();
                  if (result == null) return;
                  if (result) setState(() => Variables.hasTorch = result);
                });
              },
            ),
          ),
          Tooltip(
            message: "Toggle Microphone",
            child: IconButton(
              icon: Icon(Variables.isMicOn ? Icons.mic : Icons.mic_off),
              onPressed: () => TaskExecuter.run(taskId: 313, () async {
                final value = !Variables.isMicOn;
                if (await Requester.setMic(value)) {
                  setState(() => Variables.isMicOn = value);
                }
              }),
            ),
          ),
          Tooltip(
            message: "Toggle Flash",
            child: IconButton(
              icon: Icon(!Variables.hasTorch
                  ? Icons.no_flash
                  : Variables.isTorchOn
                      ? Icons.flash_on
                      : Icons.flash_off),
              onPressed: () => TaskExecuter.run(taskId: 544, () async {
                final value = !Variables.isTorchOn;
                if (Variables.hasTorch && await Requester.setTorch(value)) {
                  setState(() => Variables.isTorchOn = value);
                }
              }),
            ),
          ),
        ]),
        Row(children: [
          Tooltip(
            message: "Camera",
            child: ConditionalDisplayWidget(
              show: Variables.cameras != null,
              placeholderText: "Cameras",
              onPressed: () => TaskExecuter.run(taskId: 732, () async {
                if (Variables.cameras == null) {
                  final cameras = await Requester.getCameras();
                  if (cameras == null) return;
                  try {
                    setState(() {
                      Variables.cameras = deserializeCamerasInfo(cameras);
                    });
                  } catch (e) {
                    _showSnackBar(e.toString());
                  }
                }
              }),
              child: DropdownButton<int>(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16.0,
                  color: Colors.black,
                ),
                value: Variables.cameraId,
                onChanged: (cameraId) async {
                  if (await Requester.setCameraId(cameraId!)) {
                    setState(() => Variables.cameraId = cameraId);
                  }
                },
                items: Variables.cameras?.map((CameraDeviceInfo camera) {
                  return DropdownMenuItem<int>(
                    value: camera.deviceId,
                    child: Text(camera.name),
                  );
                }).toList(),
              ),
            ),
          ),
          Tooltip(
            message: "Framerate",
            child: ConditionalDisplayWidget(
              show: Variables.framerate != null,
              placeholderText: "Fps",
              onPressed: () => TaskExecuter.run(taskId: 329, () async {
                final framerate = await Requester.getFramerate();
                if (framerate != null) {
                  setState(() => Variables.framerate = framerate);
                }
              }),
              child: DropdownButton<int>(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16.0,
                  color: Colors.black,
                ),
                value: Variables.framerate,
                onChanged: (framerate) async {
                  if (await Requester.setFramerate(framerate!)) {
                    setState(() => Variables.framerate = framerate);
                  }
                },
                items: Variables.fpsRange.map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString()),
                  );
                }).toList(),
              ),
            ),
          ),
          Tooltip(
            message: "Resolution",
            child: TextButton(
              style: ElevatedButton.styleFrom(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 20.0),
              ),
              child: Text(
                Variables.resolution ?? "Resolution",
                style: const TextStyle(
                  fontSize: 16.0,
                  color: Colors.black,
                ),
              ),
              onPressed: () => TaskExecuter.run(taskId: 1108, () async {
                if (Variables.resolution == null) {
                  final resolution = await Requester.getResolution();
                  if (resolution != null) {
                    setState(() => Variables.resolution = resolution);
                  }
                  return;
                }
                if (Variables.resolutionPresets == null) {
                  final resolutionPresets =
                      await Requester.getResolutionPresets();
                  if (resolutionPresets == null) return;
                  try {
                    Variables.resolutionPresets =
                        deserializeResolutionPresets(resolutionPresets);
                  } catch (e) {
                    return _showSnackBar(e.toString());
                  }
                }
                if (Variables.resolutionPresets!.isEmpty) {
                  return _showSnackBar(
                    "No resolutions available, camera not started?",
                  );
                }
                _showResolutionPresetsDialog();
              }),
            ),
          ),
        ]),
        Row(children: [
          const Tooltip(
            message: "Manage Devices",
            child: IconButton(
              icon: Icon(Icons.device_hub),
              onPressed: DevicesManager.showDevicesDialog,
            ),
          ),
          Tooltip(
            message: "Connection Status",
            child: IconButton(
              icon: Icon(
                Icons.wifi,
                color: _isConnected ? Colors.blue : Colors.black,
              ),
              onPressed: () => showConnectionWindow(context),
            ),
          ),
        ]),
      ]),
    );
  }

  void _showResolutionPresetsDialog() {
    showDialog(
      context: context,
      builder: (context) => ResolutionPresetsDialog(
        resolutionPresets: Variables.resolutionPresets!,
        onResolutionSelected: (resolution) async {
          if (await Requester.setResolution(resolution.toString())) {
            setState(() => Variables.resolution = resolution.toString());
          } else {
            return; // on failure.
          }
          if (Variables.framerate == null) {
            final framerate = await Requester.getFramerate();
            if (framerate == null) return;
            setState(() => Variables.framerate = framerate);
          }
          if (resolution.maxFps < Variables.framerate! &&
              (await Requester.setFramerate(resolution.maxFps))) {
            setState(() => Variables.framerate = resolution.maxFps);
          }
          if (resolution.maxFps != Variables.fpsRange.last &&
              (await Requester.setMaxFramerate(resolution.maxFps))) {
            setState(() {
              Variables.fpsRange = Variables.getFpsRange(resolution.maxFps);
            });
          }
        },
      ),
    );
  }
}
