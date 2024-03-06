#include "common.h"
#include "device.h"
#include "device_enumerator.h"

#define NUM_MAX_PATHS 16
static std::string cachedPaths[NUM_MAX_PATHS];
static int numOfDevicePaths;

static Device* activeDevice = NULL;

#define TEMPORARY_BUFFER_SIZE (WIDTH * HEIGHT * 3)
static PVOID temporaryBuffer = NULL;

/**
 * @brief Initializes the necessary components.
 *
 * - Initializes COM library for multithreaded operations.
 * - Enumerates device paths.
 * - Allocates a temporary buffer.
 *
 * @return 0: Success. Initilized necessary components.
 * 1: Failure. COINIT_MULTITHREADED initialization failed.
 * 2: Failure. Device path enumeration failed.
 * 3: Failure. Temporary buffer allocation failed.
 */
EXPORT int Init()
{
	HRESULT hr = CoInitializeEx(NULL, COINIT_MULTITHREADED);
	if (!SUCCEEDED(hr))
	{
		return 1;  // COINIT_MULTITHREADED failed
	}

	numOfDevicePaths = EnumerateDevicePaths(cachedPaths, NUM_MAX_PATHS);
	if (numOfDevicePaths < 0) {
		return 2;  // device path enumeration failed
	}

	temporaryBuffer = malloc(TEMPORARY_BUFFER_SIZE);
	if (temporaryBuffer == NULL)
	{
		return 3;  // buffer allocation failed
	}

	return 0;  // success
}

/**
 * Releases resources, including the active device,
 * temporary buffer, and the COM library.
 */
EXPORT void Release()
{
	if (activeDevice != NULL)
	{
		delete activeDevice;
	}

	if (temporaryBuffer != NULL)
    {
        free(temporaryBuffer);
    }

	CoUninitialize();
}

/**
 * @brief Returns the number of available device paths.
 */
EXPORT int GetNumOfDevicePaths()
{
	return numOfDevicePaths;
}

/**
 * @brief Retrieves the device path at the specified index.
 *
 * @param[in] index Index of the device path to retrieve.
 * @param[out] str Buffer to store the retrieved device path.
 * @param[in] strBufferSize Size of the buffer for str to store.
 *
 * @return 0: Success, 1: Failure (invalid index).
 */
EXPORT int GetDevicePath(int index, char* str, int strBufferSize)
{
	if (index < 0 || index >= numOfDevicePaths) {
		return 1;  // invalid index
	}

	strcpy_s(str, strBufferSize, cachedPaths[index].c_str());

	return 0;  // success
}

/**
 * @brief Destroys the active device.
 *
 * Releasing associated resources.
 */
EXPORT void DestroyDevice()
{
	if (activeDevice != NULL)
	{
		delete activeDevice;
		activeDevice = NULL;
	}
}

/**
 * @brief Sets the active device using the specified device path.
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
 * 3: Failed to obtain the IPropertySet interface.
 * 4: Failed to determine property support.
 * 5: The device does not support property setting.
 */
EXPORT int SetDevice(const char* devicePath) 
{
	DestroyDevice();

	int status;
	IBaseFilter* filter = NULL;

	status = GetFilter(devicePath, &filter);
	if (status || filter == NULL)
	{
		return status;
	}

	activeDevice = new Device(filter);
	status = activeDevice->Init();

	if (!status)
	{
		return status; // success
	}

	delete activeDevice;
	activeDevice = NULL;

	return status + 2;
}

/**
 * @brief Sets the buffer for the active device.
 *
 * Sets the buffer for the active device using the specified data,
 * stride, width, and height, after performing necessary checks.
 *
 * @param[in] data Pointer to the data to be set as the buffer.
 * @param[in] stride Stride of the data.
 * @param[in] width Width of the data.
 * @param[in] height Height of the data.
 *
 * @return 0: Success, 1: Failure.
 *  2: Failure (invalid data length).
 * -1: Failure (no active device).
 * -2: Failure (invalid resolution).
 */
EXPORT int SetBuffer(PVOID data, DWORD stride, DWORD width, DWORD height)
{
	if (activeDevice == NULL) 
	{
		return -1;  // no active device
	}

	if (width != WIDTH || height != HEIGHT) 
	{
		return -2;  // invalid resolution
	}

	memset(temporaryBuffer, 0x00, TEMPORARY_BUFFER_SIZE);

	PUCHAR inputData = (PUCHAR)data;
	PUCHAR buffer = (PUCHAR)temporaryBuffer;
	for (ULONG y = 0; y < height; y++)
	{
		PUCHAR sourceLine = inputData + stride * y;
		PUCHAR targetLine = buffer + ((WIDTH * 3) * y);
		memcpy(targetLine, sourceLine, WIDTH * 3);
	}

	return activeDevice->SetData(temporaryBuffer, TEMPORARY_BUFFER_SIZE);
}