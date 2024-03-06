## Changes Implemented:

These adjustments have been made to meet project requirements and enhance functionality.

### For Mobile Platform:

- **getSupportedCameraResolutions:** Added a method to retrieve the supported resolutions of the camera.

### Implementations can be found in:

- `flutter-webrtc/android/src/main/java/com/cloudwebrtc/webrtc`
    - `MethodCallHandlerImpl.java`
    - `GetUserMediaImpl.java`

    These facilitate the transmission of supported resolutions to the Flutter side.

- `flutter-webrtc/android/src/main/java/com/custom/camera`
    - `CameraUtils.java`
    
    This contains the actual implementation for `CameraUtils.getSupportedResolutions`.

### For Windows Platform:

- **DriverInterface:** Implemented an interface to interact with the camera.

### Implementations can be found in:

- `flutter-webrtc/common/cpp/include`
    - `driver_interface.h`
    - `driver_interface_video_proc_thread.h`

- `flutter-webrtc/common/cpp/src`
    - `driver_interface_video_proc_thread.cc`

- `flutter-webrtc/common/cpp/src`    
    - `flutter_webrtc.cc`
    - `flutter_video_renderer.cc`

    These have been modified to handle driver interface calls and
    sending video feeds to `driver_interface_video_proc_thread`.