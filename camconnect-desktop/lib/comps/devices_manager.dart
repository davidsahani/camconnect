import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../utils/preferences.dart';
import '../utils/task_executer.dart';
import '../widgets/devices_widget.dart';
import '../widgets/resolution_presets_dialog.dart';
import '../widgets/snack_bars.dart';

class DevicesManager {
  static BuildContext? _context;
  static bool _setBufferFailed = false;
  static final _controller = StreamController<void>.broadcast();

  static bool _videoDeviceEnabled = Preferences.getVideoDeviceEnabled();

  static DriverInterfaceDevice? selectedVideoDevice;
  static List<DriverInterfaceDevice> videoDevices = [];

  static MediaDeviceInfo? selectedAudioDevice;
  static List<MediaDeviceInfo> audioDevices = [];

  static void setupDevices(BuildContext context) {
    _context = context;

    if (_videoDeviceEnabled) {
      _setupVideoDevice();
      DriverInterface.startVideoProcessing();
    }

    _setupAudioDevice();

    DriverInterface.errorStream.listen((errorMsg) {
      _setBufferFailed = errorMsg.isNotEmpty;

      if (errorMsg.isEmpty) {
        _removeSnackBar();
      } else if (_context != null) {
        showSnackBarMessage(_context!, errorMsg,
            duration: const Duration(days: 1));
      }
    });
  }

  static void _setupVideoDevice() {
    TaskExecuter.run(() async {
      videoDevices = await DriverInterface.getDevices();

      if (videoDevices.isEmpty) {
        return _showSnackBarPrompt(
          "CamConnect Camera Driver is not installed, Please install the driver.",
          "Recheck",
          _setupVideoDevice,
          dismissible: true,
        );
      }

      final videoDevicePath = Preferences.getVideoDevicePath();
      selectedVideoDevice = videoDevices.firstWhere(
        (e) => e.devicePath == videoDevicePath,
        orElse: () => videoDevices.first,
      );

      if (videoDevices.length > 1 &&
          selectedVideoDevice?.devicePath != videoDevicePath) {
        _showSnackBar(
          "Multiple camera devices found, Select the preferred one in Devices Manager.",
        );
      }

      await DriverInterface.setDevice(selectedVideoDevice!);
      _removeSnackBar(); // remove any previous snack bars being shown.
    }, onError: (e) {
      selectedVideoDevice = null; // DriverInterface.setDevice may fail.
      _showSnackBarPrompt(e.toString(), "Retry", _setupVideoDevice);
    });
  }

  static void _setupAudioDevice() {
    TaskExecuter.run(() async {
      audioDevices = await Helper.audiooutputs;
      if (audioDevices.isEmpty) {
        return;
      }
      final audioDeviceId = Preferences.getAudioDeviceId();
      selectedAudioDevice = audioDevices.firstWhere(
          (e) => e.deviceId == audioDeviceId,
          orElse: () => audioDevices.last);

      await Helper.selectAudioOutput(selectedAudioDevice!.deviceId);
    }, onError: (e) {
      selectedAudioDevice = null;
      _showSnackBar(e.toString());
    });
  }

  static void _showSnackBar(String message) {
    if (_context != null) {
      showSnackBarMessage(_context!, message,
          duration: const Duration(seconds: 5));
    }
  }

  static void _showSnackBarPrompt(
    String message,
    String buttonText,
    VoidCallback onPressed, {
    bool dismissible = false,
  }) {
    if (_context != null) {
      showSnackBarPrompt(
        _context!,
        message,
        buttonText,
        onPressed,
        dismissible: dismissible,
      );
    }
  }

  static void _removeSnackBar() {
    if (_context != null && !_setBufferFailed) {
      ScaffoldMessenger.of(_context!).removeCurrentSnackBar();
    }
  }

  static void notifyWidgetRebuild() => _controller.add(null);

  static void _refreshVideoDevices() {
    TaskExecuter.run(taskId: 1204, () async {
      final previousSelectedDevice = selectedVideoDevice;

      // It should be fine, since it's not actually being set.
      selectedVideoDevice = DriverInterfaceDevice(
          deviceName: "Fetching Devices...", devicePath: "");

      notifyWidgetRebuild(); // update the widget to show loading devices.

      await TaskExecuter.run(() async {
        videoDevices = await DriverInterface.getDevices();
        _removeSnackBar(); // remove any previous snack bars being shown.
      }, onError: (e) => _showSnackBar(e.toString()));

      if (videoDevices.isNotEmpty &&
          (previousSelectedDevice?.devicePath.isNotEmpty ?? false)) {
        selectedVideoDevice = previousSelectedDevice;
      } else {
        selectedVideoDevice = DriverInterfaceDevice(
          deviceName: videoDevices.isEmpty
              ? "No Devices Found"
              : "Devices Found: ${videoDevices.length}",
          devicePath: "",
        );
      }

      notifyWidgetRebuild(); // update the widget to show updated value.
    });
  }

  static void _refreshAudioDevices() {
    TaskExecuter.run(taskId: 1199, () async {
      final previousSelectedDevice = selectedAudioDevice;

      // It should be fine, since it's not actually being set.
      selectedAudioDevice =
          MediaDeviceInfo(label: "Fetching Devices...", deviceId: "");

      notifyWidgetRebuild(); // update the widget to show loading devices.

      await TaskExecuter.run(() async {
        audioDevices = await Helper.audiooutputs;
        _removeSnackBar(); // remove any previous snack bars being shown.
      }, onError: (e) => _showSnackBar(e.toString()));

      if (audioDevices.isNotEmpty &&
          (previousSelectedDevice?.deviceId.isNotEmpty ?? false)) {
        selectedAudioDevice = previousSelectedDevice;
      } else {
        selectedAudioDevice = MediaDeviceInfo(
          label: audioDevices.isEmpty
              ? "No Devices Found"
              : "Devices Found: ${audioDevices.length}",
          deviceId: "",
        );
      }

      notifyWidgetRebuild(); // update the widget to show updated value.
    });
  }

  static void _setVideoDevice(DriverInterfaceDevice device) {
    TaskExecuter.run(() async {
      await DriverInterface.setDevice(device);
      selectedVideoDevice = device;
      if (!await Preferences.setVideoDevicePath(device.devicePath)) {
        _showSnackBar("Failed to save preference: video-device-path");
      } else {
        _removeSnackBar(); // remove any previous snack bars being shown.
      }
      notifyWidgetRebuild(); // update the widget to show updated value.
    }, onError: (e) => _showSnackBar(e.toString()));
  }

  static void _setAudioDevice(MediaDeviceInfo device) {
    TaskExecuter.run(() async {
      await Helper.selectAudioOutput(device.deviceId);
      selectedAudioDevice = device;
      if (!await Preferences.setAudioDeviceId(device.deviceId)) {
        _showSnackBar("Failed to save preference: audio-device-id");
      } else {
        _removeSnackBar(); // remove any previous snack bars being shown.
      }
      notifyWidgetRebuild(); // update the widget to show updated value.
    }, onError: (e) => _showSnackBar(e.toString()));
  }

  static void _setVideoDeviceEnabled(bool value) {
    TaskExecuter.run(taskId: 1964, () async {
      if (value) {
        await DriverInterface.startVideoProcessing();
      } else {
        await DriverInterface.stopVideoProcessing();
        _setBufferFailed = false; // so that snackbar could be removed.
      }
      if (!await Preferences.setVideoDeviceEnabled(value)) {
        _showSnackBar("Failed to save preference: video-device-enabled");
      } else {
        _removeSnackBar(); // remove any previous snack bars being shown.
      }

      _videoDeviceEnabled = value;
      notifyWidgetRebuild(); // update the widget to show updated value.
    });
  }

  static void showDevicesDialog() {
    assert(_context != null,
        'setupDevices(BuildContext context) must be called before calling this method.');

    showDialog(
      context: _context!,
      builder: (context) => StreamBuilder<void>(
        stream: _controller.stream,
        builder: (context, snapshot) {
          return CustomDialog(
            contentPadding: const EdgeInsets.all(16.0),
            children: [
              SizedBox(
                width: 300.0,
                child: DevicesWidget(
                  videoDevices: videoDevices,
                  selectedVideoDevice: selectedVideoDevice,
                  videoDeviceEnabled: _videoDeviceEnabled,
                  onVideoDevicesRefresh: _refreshVideoDevices,
                  onVideoDeviceSelected: _setVideoDevice,
                  onVideoDeviceEnabledChanged: _setVideoDeviceEnabled,
                  // audio devices
                  audioDevices: audioDevices,
                  selectedAudioDevice: selectedAudioDevice,
                  onAudioDevicesRefresh: _refreshAudioDevices,
                  onAudioDeviceSelected: _setAudioDevice,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
