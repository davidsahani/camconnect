#ifndef DRIVER_INTERFACE_H
#define DRIVER_INTERFACE_H

#include <windows.h>

#include "device_info.h"

namespace DriverInterface {

/**
 * @brief Gets video input devices device information.
 *
 * @param[out] deviceInfos Vector to store DeviceInfos.
 *
 * @return 0 on success, or 1 on Failure.
 * -1: COM library initialization failed.
 */
int GetDevices(std::vector<DeviceInfo>& deviceInfos);

/**
 * @brief Sets the active video device using the specified device path.
 *
 * Including obtaining the filter and initializing the device.
 *
 * @param[in] devicePath The device path to set as the active device.
 *
 * @return 0: Success,
 * 1: Failure (device not found).
 * 2: Failed to create filter.
 *-1: Failed to enumerate devices.
 *-2: No video input device available.
 *-3: COM library initialization failed.
 * 3: Failed to obtain the IPropertySet interface.
 * 4: Failed to determine property support.
 * 5: The device does not support property setting.
 */
int SetDevice(const std::string& devicePath);

/**
 * @brief Destroys the active video device.
 */
void DestroyDevice();

/**
 * @brief Releases active resources.
 *
 * Including the COM library and active device.
 */
void Release();

/**
 * @brief Sets the buffer for the active device with the specified RGB data.
 *
 * @param[in] data Pointer to the RGB data to be set as the buffer.
 * @param[in] dataLength buffer length of the RGB data.
 *
 * @return 0: Success, 1: Failure.
 * -1: Failure (no active device).
 */
int SetBuffer(PVOID data, const DWORD &dataLength) noexcept;

}  // namespace DriverInterface

#endif // DRIVER_INTERFACE_H
