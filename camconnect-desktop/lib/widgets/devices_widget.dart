import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'overlay_entry_creator.dart';

class DevicesWidget extends StatelessWidget {
  const DevicesWidget({
    super.key, // video devices
    required this.videoDevices,
    required this.selectedVideoDevice,
    required this.videoDeviceEnabled,
    required this.onVideoDevicesRefresh,
    required this.onVideoDeviceSelected,
    required this.onVideoDeviceEnabledChanged,
    // audio devices
    required this.audioDevices,
    required this.selectedAudioDevice,
    required this.onAudioDevicesRefresh,
    required this.onAudioDeviceSelected,
  });

  final bool videoDeviceEnabled;
  final VoidCallback onVideoDevicesRefresh;
  final List<DriverInterfaceDevice> videoDevices;
  final DriverInterfaceDevice? selectedVideoDevice;
  final void Function(DriverInterfaceDevice) onVideoDeviceSelected;
  final void Function(bool) onVideoDeviceEnabledChanged;

  final List<MediaDeviceInfo> audioDevices;
  final VoidCallback onAudioDevicesRefresh;
  final MediaDeviceInfo? selectedAudioDevice;
  final void Function(MediaDeviceInfo) onAudioDeviceSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Camera Device:",
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10.0),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              width: 1.6, // Border width
              color: const Color.fromARGB(255, 0, 191, 255),
            ),
          ),
          child: ListTile(
            leading: _DeviceSelectionDropdownButton(
              devices: videoDevices,
              selectedDevice: selectedVideoDevice,
              onSelected: onVideoDeviceSelected,
            ),
            trailing: ElevatedButton(
              onPressed: onVideoDevicesRefresh,
              onLongPress: onVideoDevicesRefresh,
              child: const Text("Refresh"),
            ),
            contentPadding: const EdgeInsets.only(left: 0.0, right: 4.0),
          ),
        ),
        // audio device
        const SizedBox(height: 15.0),
        const Text(
          "Select Audio Output Device:",
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10.0),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              width: 1.6, // Border width
              color: const Color.fromARGB(255, 0, 191, 255),
            ),
          ),
          child: ListTile(
            leading: _CustomDropdownButton(
              devices: audioDevices,
              selectedDevice: selectedAudioDevice,
              onSelected: onAudioDeviceSelected,
            ),
            trailing: ElevatedButton(
              onPressed: onAudioDevicesRefresh,
              onLongPress: onAudioDevicesRefresh,
              child: const Text("Refresh"),
            ),
            contentPadding: const EdgeInsets.only(left: 0.0, right: 4.0),
          ),
        ),
        const SizedBox(height: 60.0),
        SwitchListTile(
          title: Text(
              "${videoDeviceEnabled ? "Disable" : "Enable"} Camera Device"),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
          value: videoDeviceEnabled,
          onChanged: onVideoDeviceEnabledChanged,
        ),
      ],
    );
  }
}

class _DeviceSelectionDropdownButton extends StatefulWidget {
  final DriverInterfaceDevice? selectedDevice;
  final List<DriverInterfaceDevice> devices;
  final void Function(DriverInterfaceDevice) onSelected;

  const _DeviceSelectionDropdownButton({
    required this.selectedDevice,
    required this.devices,
    required this.onSelected,
  });

  @override
  State<_DeviceSelectionDropdownButton> createState() =>
      _DeviceSelectionDropdownButtonState();
}

class _DeviceSelectionDropdownButtonState
    extends State<_DeviceSelectionDropdownButton> {
  OverlayEntryCreator? _overlayEntryCreator;

  @override
  void initState() {
    _overlayEntryCreator = OverlayEntryCreator(context);
    super.initState();
  }

  @override
  void dispose() {
    _overlayEntryCreator?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200.0,
      child: ListTile(
        leading: SizedBox(
          width: 187.0,
          child: Text(
            widget.selectedDevice?.deviceName ?? "",
            style: const TextStyle(fontSize: 14.5),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: const Icon(Icons.arrow_drop_down),
        contentPadding: const EdgeInsets.only(left: 8.0, right: 4.0),
        onTap: () {
          _overlayEntryCreator?.create(
            _DeviceSelectionDropdownEntries(
              devices: widget.devices,
              onSelected: (value) {
                widget.onSelected(value);
                _overlayEntryCreator?.remove();
              },
            ),
            widget.devices.length,
          );
        },
      ),
    );
  }
}

class _DeviceSelectionDropdownEntries extends StatelessWidget {
  const _DeviceSelectionDropdownEntries({
    required this.devices,
    required this.onSelected,
  });

  final List<DriverInterfaceDevice> devices;
  final void Function(DriverInterfaceDevice) onSelected;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: devices.map((device) {
            return SimpleDialogOption(
              padding: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.deviceName,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    const Divider(height: 0.0, thickness: 1.2),
                    Text(
                      device.devicePath,
                      style: const TextStyle(fontSize: 12.0),
                    ),
                  ],
                ),
              ),
              onPressed: () => onSelected(device),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// #======================> Custom Dropdown <========================# //

class _CustomDropdownButton extends StatefulWidget {
  final MediaDeviceInfo? selectedDevice;
  final List<MediaDeviceInfo> devices;
  final void Function(MediaDeviceInfo) onSelected;

  const _CustomDropdownButton({
    required this.selectedDevice,
    required this.devices,
    required this.onSelected,
  });

  @override
  State<_CustomDropdownButton> createState() => _CustomDropdownButtonState();
}

class _CustomDropdownButtonState extends State<_CustomDropdownButton> {
  OverlayEntryCreator? _overlayEntryCreator;

  @override
  void initState() {
    _overlayEntryCreator = OverlayEntryCreator(context);
    super.initState();
  }

  @override
  void dispose() {
    _overlayEntryCreator?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200.0,
      child: ListTile(
        leading: SizedBox(
          width: 187.0,
          child: Text(
            widget.selectedDevice?.label ?? "",
            style: const TextStyle(fontSize: 14.5),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: const Icon(Icons.arrow_drop_down),
        contentPadding: const EdgeInsets.only(left: 8.0, right: 4.0),
        onTap: () {
          _overlayEntryCreator?.create(
            _CustomDropdownEntries(
              devices: widget.devices,
              onSelected: (value) {
                widget.onSelected(value);
                _overlayEntryCreator?.remove();
              },
            ),
            widget.devices.length,
          );
        },
      ),
    );
  }
}

class _CustomDropdownEntries extends StatelessWidget {
  const _CustomDropdownEntries({
    required this.devices,
    required this.onSelected,
  });

  final List<MediaDeviceInfo> devices;
  final void Function(MediaDeviceInfo) onSelected;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: devices.map((device) {
            return SimpleDialogOption(
              padding: const EdgeInsets.all(15.0),
              child: Text(
                device.label,
                style: const TextStyle(fontSize: 14.0),
              ),
              onPressed: () => onSelected(device),
            );
          }).toList(),
        ),
      ),
    );
  }
}
