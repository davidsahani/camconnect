import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:wakelock/wakelock.dart';

import '../utils/orientation_manager.dart';
import '../utils/preferences.dart';
import '../utils/settings_manager.dart';
import '../utils/task_executer.dart';
import '../widgets/resolution_presets_button.dart';
import '../widgets/snack_bars.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isMicrophoneEnabled = Preferences.getMicEnabled();
  bool _isWakeLockEnabled = Preferences.getWakeLockEnabled();
  bool _isAutoDimScreenEnabled = Preferences.getAutoDimScreenEnabled();

  int _currentFps = Preferences.getFps();
  String _orientation = Preferences.getOrientation();
  Resolution _selectedResolution = SettingsManager.getResolution();

  MediaDeviceInfo? _selectedCamera;
  List<MediaDeviceInfo> _availableCameras = [];
  Map<ResolutionPreset, List<Resolution>> _resolutionPresets = {};

  // List of available FPS values
  late List<int> _fpsRange;

  @override
  void initState() {
    _initialize();
    super.initState();
  }

  void _initialize() async {
    _fpsRange = _getFpsRange(_selectedResolution.maxFps);

    _availableCameras = await Helper.cameras;
    if (_availableCameras.isNotEmpty) {
      final cameraId = Preferences.getCameraId();
      _selectedCamera = _availableCameras[cameraId];
    }

    // execute ignoring error: treating it as 'No Resolutions Available' on failure.
    await TaskExecuter.run(() async {
      _resolutionPresets = await SettingsManager.getResolutionPresets();
    });

    setSafeState(() {}); // rebuild widgets to show updated values.
  }

  List<int> _getFpsRange(int maxFps) {
    List<int> fpsRange = [];
    for (int i = 5; i <= maxFps; i += 5) {
      fpsRange.add(i);
    }
    return fpsRange;
  }

  void setSafeState(VoidCallback callback) {
    if (mounted) setState(callback);
  }

  void _showSnackBarMessage(String message) =>
      showSnackBarMessage(context, message);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: false,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Settings"),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: const Text("Default Camera"),
                trailing: DropdownButton<MediaDeviceInfo>(
                  value: _selectedCamera,
                  onChanged: (camera) => TaskExecuter.run(() async {
                    await SettingsManager.setCameraId(
                        int.parse(camera!.deviceId));
                    setSafeState(() => _selectedCamera = camera);
                  }, onError: (e) => _showSnackBarMessage(e.toString())),
                  items: _availableCameras.map((camera) {
                    return DropdownMenuItem<MediaDeviceInfo>(
                      value: camera,
                      child: Text(
                        SettingsManager.formatCameraLabel(camera.label),
                      ),
                    );
                  }).toList(),
                ),
              ),
              ListTile(
                title: const Text("Streaming Orientation"),
                trailing: DropdownButton<String>(
                    value: _orientation,
                    onChanged: (orientation) {
                      TaskExecuter.run(() async {
                        await SettingsManager.setOrientation(orientation!);
                        setSafeState(() => _orientation = orientation);
                      }, onError: (e) => _showSnackBarMessage(e.toString()));
                    },
                    items: OrientationManger.deviceOrientations()
                        .map((orientation) {
                      return DropdownMenuItem<String>(
                        value: orientation,
                        child: Text(orientation),
                      );
                    }).toList()),
              ),
              SwitchListTile(
                title: const Text("Keep Device Awake"),
                value: _isWakeLockEnabled,
                onChanged: (value) => TaskExecuter.run(taskId: 894, () async {
                  if (!await Preferences.setWakeLockEnabled(value)) {
                    _showSnackBarMessage(
                        "Failed to save preference: wake-lock");
                  }
                  await Wakelock.toggle(enable: value);
                  setSafeState(() => _isWakeLockEnabled = value);
                }, onError: (e) => _showSnackBarMessage(e.toString())),
              ),
              SwitchListTile(
                title: const Text("Dim Screen Automatically"),
                value: _isAutoDimScreenEnabled,
                onChanged: (value) => TaskExecuter.run(taskId: 999, () async {
                  if (!await Preferences.setAutoDimScreenEnabled(value)) {
                    _showSnackBarMessage(
                        "Failed to save preference: auto-dim-screen");
                  }
                  setState(() => _isAutoDimScreenEnabled = value);
                }),
              ),
              SwitchListTile(
                title: const Text("Capture Microphone"),
                value: _isMicrophoneEnabled,
                onChanged: (enable) => TaskExecuter.run(taskId: 313, () async {
                  if (await SettingsManager.setMicEnabled(enable)) {
                    setSafeState(() => _isMicrophoneEnabled = enable);
                  }
                }),
              ),
              ListTile(
                title: const Text("Framerate"),
                trailing: DropdownButton<int>(
                  value: _currentFps,
                  onChanged: (framerate) => TaskExecuter.run(() async {
                    await SettingsManager.setFps(framerate!);
                    setSafeState(() => _currentFps = framerate);
                  }, onError: (e) => _showSnackBarMessage(e.toString())),
                  items: _fpsRange.map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString()),
                    );
                  }).toList(),
                ),
              ),
              ResolutionPresetsButton(
                selectedResolution: _selectedResolution,
                resolutionPresets: _resolutionPresets,
                onResolutionSelected: (resolution) async {
                  final status = await TaskExecuter.run(() async {
                    await SettingsManager.setResolution(resolution.toString());
                    setSafeState(() => _selectedResolution = resolution);
                  }, onError: (e) => _showSnackBarMessage(e.toString()));
                  if (!(status ?? false)) {
                    return; // on failure.
                  }
                  // update framerate and framerate range
                  if (_selectedResolution.maxFps < _currentFps) {
                    await TaskExecuter.run(() async {
                      await SettingsManager.setFps(_selectedResolution.maxFps);
                      setSafeState(() {
                        _currentFps = _selectedResolution.maxFps;
                      });
                    }, onError: (e) => _showSnackBarMessage(e.toString()));
                  }
                  if (_fpsRange.last != _selectedResolution.maxFps) {
                    await TaskExecuter.run(() async {
                      await SettingsManager.setMaxFps(
                          _selectedResolution.maxFps);
                      setSafeState(() {
                        _fpsRange = _getFpsRange(_selectedResolution.maxFps);
                      });
                    }, onError: (e) => _showSnackBarMessage(e.toString()));
                  }
                },
                onEmptyResolutions: () => _showSnackBarMessage(
                  SettingsManager.localStream != null
                      ? "No resolutions available."
                      : "Resolutions unavailable, camera not started.",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
