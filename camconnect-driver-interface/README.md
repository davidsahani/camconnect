# CamConnect Driver Interface
This project provides a C++ interface for interacting with video input devices of camconnect driver. It provides a simple API for enumerating devices, setting an active device, managing buffers, and releasing resources.

## Getting Started

The DriverInterface is provided as a C++ header file (`driver_interface.h`) and import library (`DriverInterface.lib`). Include the header and link against the import library to use it in your project.

### Example Usage:

```cpp
#include "driver_interface.h"

int main() {

  // Get list of available devices
  std::vector<DeviceInfo> devices;
  int result = DriverInterface::GetDevices(devices);

  // Set first device 
  if(!devices.empty()) {
    DriverInterface::SetDevice(devices[0].devicePath); 
  }

  // Set buffer data
  DriverInterface::SetBuffer(bufferData, bufferLength);

  // Release resources
  DriverInterface::Release();
}
```