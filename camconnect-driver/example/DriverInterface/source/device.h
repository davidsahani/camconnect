#pragma once

#include "common.h"

#define PROP_GUID 0xcb043957, 0x7b35, 0x456e, 0x9b, 0x61, 0x55, 0x13, 0x93, 0xf, 0x4d, 0x8e
#define PROP_DATA_ID 0

#define WIDTH 1280
#define HEIGHT 720

class Device
{
private:
	IBaseFilter* filter;
	IKsPropertySet* propertySet;
public:
	Device(IBaseFilter* filter);
	~Device();

	/**
	 * @brief Initializes the Device object.
	 *
	 * Initializes the Device object by obtaining the IPropertySet
	 * interface for the device's filter and checking if the device supports
	 * property setting.
	 *
	 * @return 0: Success,
	 * 1: Failed to obtain the IPropertySet interface.
	 * 2: Failed to determine property support.
	 * 3: The device does not support property setting.
	 */
	int Init();

	/**
	 * @brief Sets data for the virtual camera driver for the Device object.
	 *
	 * Uses the IPropertySet interface to set the specified data with the provided length.
	 *
	 * @param[in] dataPointer Pointer to the data to be set.
	 * @param[in] dataLength Length of the data to be set.
	 *
	 * @return 0: Success, 1: Failure.
	 * 2: Failure (invalid data length).
	 */
	int SetData(PVOID dataPointer, const ULONG& dataLength);
};
