import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class ResolutionPresetsButton extends StatelessWidget {
  const ResolutionPresetsButton({
    required this.selectedResolution,
    required this.resolutionPresets,
    required this.onResolutionSelected,
    this.onEmptyResolutions,
    super.key,
  });

  final Resolution selectedResolution;
  final void Function(Resolution) onResolutionSelected;
  final Map<ResolutionPreset, List<Resolution>> resolutionPresets;
  final VoidCallback? onEmptyResolutions;

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      padding: EdgeInsets.zero,
      child: ListTile(
        title: const Text(
          "Resolution",
          style: TextStyle(fontSize: 16.5),
        ),
        trailing: Text(
          selectedResolution.toString(),
          style: const TextStyle(fontSize: 16.0),
        ),
      ),
      onPressed: () {
        if (resolutionPresets.isEmpty) {
          onEmptyResolutions?.call();
        } else {
          _showPresetsDialog(context);
        }
      },
    );
  }

  void _showPresetsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        children: [
          _buildDialogOption(context, "Low", ResolutionPreset.low),
          _buildDialogOption(context, "Medium", ResolutionPreset.medium),
          _buildDialogOption(context, "High", ResolutionPreset.high),
          _buildDialogOption(context, "Very High", ResolutionPreset.veryHigh),
          // we can't use ultraHigh preset currently seemingly those
          // resolutions are not supported by flutter_webrtc package.
          // _buildDialogOption(context, "Ultra High", ResolutionPreset.ultraHigh),
        ],
      ),
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
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
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
          ),
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
