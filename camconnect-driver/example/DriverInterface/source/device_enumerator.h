#pragma once

#include "common.h"

/**
 * @brief Enumerates device paths for video input devices.
 *
 * @param[out] devicePaths Array to store device paths.
 * @param[in] maxPathsCount Maximum number of paths to retrieve.
 *
 * @return The number of device paths found, or -1 if enumeration failed.
 */
int EnumerateDevicePaths(std::string* devicePaths, const int& maxPathsCount);

/**
 * @brief Gets the filter for the specified device path.
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
int GetFilter(const char* devicePath, IBaseFilter** filter);