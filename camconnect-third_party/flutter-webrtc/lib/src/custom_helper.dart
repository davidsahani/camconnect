import 'package:flutter_webrtc/flutter_webrtc.dart';

class CustomHelper {
  static Future<List<Map<String, int>>> getSupportedCameraResolutions(
      String trackId) async {
    List<dynamic> resolutions = await WebRTC.invokeMethod(
      'getSupportedCameraResolutions',
      <String, dynamic>{'trackId': trackId},
    );

    return resolutions
        .map<Map<String, int>>((dynamic resolution) => {
              'width': resolution['width']!,
              'height': resolution['height']!,
              'maxFps': resolution['maxFps']!,
            })
        .toList();
  }

  static Future<Map<ResolutionPreset, List<Resolution>>> getResolutionPresets(
      MediaStream stream) async {
    final tracks = stream.getVideoTracks();
    if (tracks.isEmpty) {
      throw 'MediaStream has no video tracks.';
    }
    final trackId = tracks.first.id;
    if (trackId == null) {
      throw 'MediaStream video trackId is null.';
    }

    final categorizedResolutions = <ResolutionPreset, List<Resolution>>{
      ResolutionPreset.low: [],
      ResolutionPreset.medium: [],
      ResolutionPreset.high: [],
      ResolutionPreset.veryHigh: [],
      ResolutionPreset.ultraHigh: [],
    };

    void categorizeResolution(Map<String, int> resolutionMap) {
      final width = resolutionMap['width']!;
      final height = resolutionMap['height']!;

      final resolution = Resolution(
        width: width,
        height: height,
        maxFps: resolutionMap['maxFps']!,
      );

      if (width <= 320 && height <= 240) {
        categorizedResolutions[ResolutionPreset.low]!.add(resolution);
      } else if (width <= 720 && height <= 480) {
        categorizedResolutions[ResolutionPreset.medium]!.add(resolution);
      } else if (width <= 1280 && height <= 720) {
        categorizedResolutions[ResolutionPreset.high]!.add(resolution);
      } else if (width <= 1920 && height <= 1080) {
        categorizedResolutions[ResolutionPreset.veryHigh]!.add(resolution);
      } else {
        categorizedResolutions[ResolutionPreset.ultraHigh]!.add(resolution);
      }
    }

    final resolutions = await getSupportedCameraResolutions(trackId);

    for (final resolution in resolutions) {
      categorizeResolution(resolution);
    }

    return categorizedResolutions;
  }
}

class Resolution {
  Resolution({
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
