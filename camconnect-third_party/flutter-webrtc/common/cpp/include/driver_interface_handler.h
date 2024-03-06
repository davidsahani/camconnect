#ifndef DRIVER_INTERFACE_HANDLER_H
#define DRIVER_INTERFACE_HANDLER_H

#include "flutter_common.h"
#include "driver_interface.h"
#include "driver_interface_video_proc_thread.h"

inline bool HandleDriverInterfaceMethodCall(const MethodCallProxy& method_call, std::unique_ptr<MethodResultProxy>& result)
{
  const flutter::EncodableValue* arguments = method_call.arguments();
  if (!arguments) {
    result->Error("Bad Arguments", "Null arguments received");
    return false;
  }

  const flutter::EncodableMap* params = std::get_if<EncodableMap>(arguments);

  static const std::unordered_map<std::string, std::function<void()>> methodHandlers = {
    {"DriverInterface::GetDevices", [&] {
      std::vector<DeviceInfo> devicesInfo;
      const int status = DriverInterface::GetDevices(devicesInfo);

      if (status) {
        if (status == -1) {
          result->Error("DriverInterface::GetDevices", "COM library initialization failed.");
        } else {
          result->Error("DriverInterface::GetDevices", "Failed to get devices information.");
        }
        return; // on failure
      }

      EncodableList deviceInfoList;

      for (const DeviceInfo deviceInfo : devicesInfo) {
        EncodableMap info;
        info[EncodableValue("deviceName")] = EncodableValue(deviceInfo.friendlyName);
        info[EncodableValue("devicePath")] = EncodableValue(deviceInfo.devicePath);
        deviceInfoList.push_back(EncodableValue(info));
      }

      result->Success(EncodableValue(deviceInfoList));
    }},
    {"DriverInterface::SetDevice", [&] {
        if (params == nullptr) {
          return result->Error("Missing Arguments",
            "DriverInterface::SetDevice requires an argument named 'devicePath'."
          );
        }

        const std::string devicePath = findString(*params, "devicePath");
        if (devicePath.empty()) {
          return result->Error("Invalid Argument",
            "DriverInterface::SetDevice argument 'devicePath' cannot be empty.");
        }

        const int status = DriverInterface::SetDevice(devicePath);

        switch (status) {
          case 0:
            result->Success();
            break;
          case 1:
            result->Error("DriverInterface::SetDevice", "Device not found.");
            break;
          case 2:
            result->Error("DriverInterface::SetDevice", "Failed to create filter.");
            break;
          case 3:
            result->Error("DriverInterface::SetDevice", "Failed to obtain the IPropertySet interface.");
            break;
          case 4:
            result->Error("DriverInterface::SetDevice", "Failed to determine property support.");
            break;
          case 5:
            result->Error("DriverInterface::SetDevice", "The device does not support property setting.");
            break;
          case -1:
            result->Error("DriverInterface::SetDevice", "Failed to enumerate devices.");
            break;
          case -2:
            result->Error("DriverInterface::SetDevice", "No Video input device available.");
            break;
          case -3:
            result->Error("DriverInterface::SetDevice", "COM library initialization failed.");
            break;
          default:
            result->Error("DriverInterface::SetDevice",
                "Failed with unknown status code: " + std::to_string(status)
              );
            break;
        }
    }},
    {"DriverInterface::DestroyDevice", [&] {
      DriverInterface::DestroyDevice();
      result->Success();
    }},
    {"DriverInterface::Release", [&] {
      DriverInterface::Release();
      result->Success();
    }},
    {"DriverInterface::StartVideoProcessing", [&] {
      driver_interface::VideoProcessingThread::Start();
      result->Success();
    }},
    {"DriverInterface::StopVideoProcessing", [&] {
      driver_interface::VideoProcessingThread::Stop();
      result->Success();
    }},
  };

  auto it = methodHandlers.find(method_call.method_name());
  if (it != methodHandlers.end()) {
    it->second();
  } else {
    return false;
  }
  return true;
}

namespace driver_interface {

std::unique_ptr<EventChannelProxy> event_channel_;

class DriverInterfaceEventHandler {
public:
  static void Initialize(BinaryMessenger* messenger) {
    std::string channel_name = "DriverInterface/VideoProcessingEvent";

    event_channel_ = EventChannelProxy::Create(messenger, channel_name);

    VideoProcessingThread::SetCallback([&](const std::string& errorMsg) {
        event_channel_->Success(EncodableValue(errorMsg));
    });
  }

  static void Release() {
    event_channel_.reset();
  }
};

}  // namespace driver_interface

#endif // DRIVER_INTERFACE_HANDLER_H