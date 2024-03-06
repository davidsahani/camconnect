import 'package:flutter/material.dart';

import '../utils/resolution_presets.dart';

class ResolutionPresetsDialog extends StatelessWidget {
  const ResolutionPresetsDialog({
    required this.resolutionPresets,
    required this.onResolutionSelected,
    super.key,
  });

  final void Function(Resolution) onResolutionSelected;
  final Map<ResolutionPreset, List<Resolution>> resolutionPresets;

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      children: [
        _buildDialogOption(context, "Low", ResolutionPreset.low),
        _buildDialogOption(context, "Medium", ResolutionPreset.medium),
        _buildDialogOption(context, "High", ResolutionPreset.high),
        _buildDialogOption(context, "Very High", ResolutionPreset.veryHigh),
        // we can't use ultraHigh preset currently seemingly those
        // resolutions are not supported by flutter_webrtc package.
        // _buildDialogOption(context, "Ultra High", ResolutionPreset.ultraHigh),
      ],
    );
  }

  SimpleDialogOption _buildDialogOption(
    BuildContext context,
    String presetName,
    ResolutionPreset preset,
  ) {
    final resolutions = resolutionPresets[preset];

    if (resolutions == null || resolutions.isEmpty) {
      return SimpleDialogOption(
        child: ListTile(
          leading: Text(
            "$presetName (preset)",
            style: const TextStyle(fontSize: 15.0),
          ),
          trailing: const Text(
            "(Unavailable)",
            style: TextStyle(fontSize: 16.5),
          ),
        ),
        onPressed: () => Navigator.pop(context),
      );
    }

    final selectedResolution = resolutions.first;

    return SimpleDialogOption(
      child: ListTile(
        leading: Text(
          "$presetName ($selectedResolution)",
          style: const TextStyle(fontSize: 15.0),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: () {
            Navigator.pop(context);
            _showResolutionsDialog(context, presetName, preset);
          },
        ),
      ),
      onPressed: () {
        onResolutionSelected(selectedResolution);
        Navigator.pop(context); // close dialog
      },
    );
  }

  void _showResolutionsDialog(
      BuildContext context, String presetName, ResolutionPreset preset) {
    final resolutions = resolutionPresets[preset];

    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: Text(
          "$presetName Resolutions",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18.0),
        ),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: resolutions!.map((resolution) {
                  return SimpleDialogOption(
                    padding: const EdgeInsets.all(15.0),
                    child: Text(
                      resolution.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16.0),
                    ),
                    onPressed: () {
                      onResolutionSelected(resolution);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class CustomDialog extends SimpleDialog {
  CustomDialog({
    Key? key,
    EdgeInsets? insetPadding,
    Color? backgroundColor,
    Color? surfaceTintColor,
    ShapeBorder? shape,
    Widget? title,
    List<Widget>? children,
    EdgeInsetsGeometry? contentPadding,
  }) : super(
          key: key,
          title: title,
          children: children,
          backgroundColor: backgroundColor,
          insetPadding: insetPadding ?? EdgeInsets.zero,
          surfaceTintColor: surfaceTintColor ?? Colors.white,
          shape: shape ??
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
          contentPadding:
              contentPadding ?? const EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 16.0),
        );
}
