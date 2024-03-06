#pragma once

#include "common.h"
#include "device_info.h"

/**
 * @brief Enumerates video input devices and retrieves device information.
 *
 * @param[out] deviceInfos Vector to store DeviceInfo.
 *
 * @return 0 on success, or 1 if device enumeration failed.
 */
int EnumerateDevices(std::vector<DeviceInfo>& deviceInfos);

/**
 * @brief Gets the video filter for the specified device path.
 *
 * @param[in] devicePath The path of the device to get the filter for.
 * @param[out] filter Pointer to the IBaseFilter interface for the device.
 *
 * @return 0: Success (device found).
 *  1: Failure (device not found).
 *  2: Failed to create filter.
 * -1: Failed to enumerate devices.
 * -2: No video input device available.
 */
int GetFilter(const std::string& devicePath, IBaseFilter** filter);