#ifndef DEVICE_INFO_H
#define DEVICE_INFO_H

#include <string>
#include <vector>

/**
 * @brief Represents information about a device.
 */
struct DeviceInfo
{
    std::string friendlyName;  // A user-friendly name for the device.
    std::string devicePath;    // The path of the device.
};


#endif // DEVICE_INFO_H
