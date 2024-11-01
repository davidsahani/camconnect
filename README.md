# CamConnect: Seamlessly connect your smartphone webcam to your PC

CamConnect lets you turn your smartphone into a wireless webcam for your PC, providing a seamless and efficient solution for your webcam needs. Unlike other apps available in the industry, CamConnect focuses on enhancing key areas to deliver an exceptional user experience.

## Key Features:

1. **User Interface Enhancement**: CamConnect boasts a better UI (User Interface) that simplifies navigation and enhances usability, ensuring a smooth and intuitive experience for users.

2. **Automatic Device Discovery**: With CamConnect, connecting your devices is effortless. The app facilitates automatic device discovery, eliminating the need for manual intervention. Simply open the apps, and they'll find each other seamlessly.

3. **Hardware Encoding**: To optimize performance and conserve battery life, CamConnect utilizes hardware-based encoding. This approach minimizes CPU usage while delivering high-quality video streams.

4. **Unrestricted Resolution Camera Feed Streaming**: Enjoy unrestricted and specific resolution streaming tailored to your device's capabilities. CamConnect ensures that you can stream in the highest possible quality supported by your device and underlying framework.

5. **Cross-Device Settings Adjustment**: With CamConnect, you can conveniently adjust streaming preferences and settings from both the mobile and desktop sides. This unique feature offers flexibility and customization options to suit your needs.

### App preview:

<img src="images/preview.gif"/>

## Building CamConnect

Follow these steps to successfully build camconnect on your system.

### 1. Install Flutter

Install Flutter by following the instructions provided in the [Getting started with Flutter](https://docs.flutter.dev/get-started/install).

**Visual Studio Development Tools:**

Download the [Visual Studio](https://docs.flutter.dev/get-started/install/windows/desktop#development-tools) version mentioned in the Flutter documentation and select the `Desktop development with C++` workload. You can also use [Visual C++ Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/) if preferred.

### 2. Verify Installation

- Confirm that Flutter is added to your system's PATH environment variable to execute it from the command line.

- Ensure you have installed the necessary build dependencies for Flutter to run successfully.

- Run `flutter doctor` in the command line to verify that there are no issues.

### 3. Install Inno setup installer
1. Download Inno Setup from here: https://jrsoftware.org/isinfo.php

2. Open the setup and install it on your system.

3. Make sure it is installed in `C:\Program Files (x86)`.

### 4. Build Projects

1. Open a command prompt and navigate to the project directory.

2. Run the following command to build the projects:
```bash
python build.py
```

**Note:** Build script will build the applications in release mode and copy the binaries to the `project/build` directory.