## Build Instructions for CamConnect

Follow these steps to successfully build camconnect on your system.

### 1. Install Flutter

Install Flutter by following the instructions provided in the [Getting started with Flutter](https://docs.flutter.dev/get-started/install).

**Visual Studio Development Tools:**

- If you intend to build `camconnect-driver`, ensure you have Visual Studio 2019 installed. Refer to the `camconnect-driver` [README.md](camconnect-driver/README.md) for further details.

- Otherwise, download the [Visual Studio](https://docs.flutter.dev/get-started/install/windows/desktop#development-tools) version mentioned in the Flutter documentation and select the `Desktop development with C++` workload. You can also use [Visual C++ Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/) if preferred.

### 2. Verify Installation

- Confirm that Flutter is added to your system's PATH environment variable to execute it from the command line.

- Ensure you have installed the necessary build dependencies for Flutter to run successfully.

- Run `flutter doctor` in the command line to verify that there are no issues.

### 3. Build Projects

1. Open a command prompt and navigate to the project directory.

2. Run the following command to build the projects:
```bash
python build.py
```

**Note:** Build script will build the applications in release mode and copy the binaries to the `project/build` directory.