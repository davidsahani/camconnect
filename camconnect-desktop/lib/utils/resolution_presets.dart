class Resolution {
  const Resolution({
    required this.width,
    required this.height,
    required this.maxFps,
  });

  final int width;
  final int height;
  final int maxFps;

  @override
  String toString() => "${width}x$height";
}

enum ResolutionPreset {
  /// 352x288 on iOS, 240p (320x240) on Android and Web
  low,

  /// 480p (640x480 on iOS, 720x480 on Android and Web)
  medium,

  /// 720p (1280x720)
  high,

  /// 1080p (1920x1080)
  veryHigh,

  /// 2160p (3840x2160 on Android and iOS, 4096x2160 on Web)
  ultraHigh,
}

Map<ResolutionPreset, List<Resolution>> deserializeResolutionPresets(
    Map<String, dynamic> resolutionPresets) {
  return Map.fromEntries(resolutionPresets.entries.map((entry) {
    List<Resolution> resolutions = [];
    for (Map<String, dynamic> res in entry.value) {
      resolutions.add(Resolution(
        width: res['width'],
        height: res['height'],
        maxFps: res['maxFps'],
      ));
    }
    return MapEntry(
        ResolutionPreset.values.firstWhere((e) => e.name == entry.key),
        resolutions);
  }));
}

class CameraDeviceInfo {
  const CameraDeviceInfo({
    required this.name,
    required this.deviceId,
  });

  final String name;
  final int deviceId;
}

List<CameraDeviceInfo> deserializeCamerasInfo(List<dynamic> cameraDeviceInfos) {
  return cameraDeviceInfos.map((info) {
    return CameraDeviceInfo(
      name: info['name']!,
      deviceId: int.parse(info['id']!),
    );
  }).toList();
}
