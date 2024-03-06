#include "device_enumerator.h"

/**
 * @brief Enumerates devices of the specified category.
 *
 * Creates an enumerator for devices of the specified category
 * and returns it through the ppEnum parameter.
 *
 * @param[in] category The category of devices to enumerate.
 * @param[out] ppEnum Pointer to the enumerator interface.
 *
 * @return HRESULT indicating success or failure.
 */
HRESULT CreateDeviceEnumerator(REFGUID category, IEnumMoniker **ppEnum)
{
	ICreateDevEnum *pDevEnum;
	HRESULT hr = CoCreateInstance(CLSID_SystemDeviceEnum, NULL,
		CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&pDevEnum));

	if (SUCCEEDED(hr))
	{
		hr = pDevEnum->CreateClassEnumerator(category, ppEnum, 0);
		pDevEnum->Release();
	}
	return hr;
}

int EnumerateDevicePaths(std::string* devicePaths, const int& maxPathsCount)
{
	IEnumMoniker *pEnum;
	if (!SUCCEEDED(CreateDeviceEnumerator(CLSID_VideoInputDeviceCategory, &pEnum)))
	{
		return -1;	// device enumeration failed
	}

	if (pEnum == nullptr)
	{
		return 0;  // no video input device available.
	}

	int index = 0;
	IMoniker *pMoniker = NULL;

	while (pEnum->Next(1, &pMoniker, NULL) == S_OK && index < maxPathsCount)
	{
		LPOLESTR str;
		if (!SUCCEEDED(pMoniker->GetDisplayName(0, 0, &str))) {
			continue;
		}

		size_t numChars = 0;
		char cstr[1024];
		wcstombs_s(&numChars, cstr, str, 512);
		CoTaskMemFree(str);  // Free the memory allocated

		devicePaths[index].assign(cstr);
		++index;
	}

	pEnum->Release();
	return index;  // number of device paths
}

int GetFilter(const char* devicePath, IBaseFilter** filter)
{
	IEnumMoniker *pEnum;
	HRESULT hr = CreateDeviceEnumerator(CLSID_VideoInputDeviceCategory, &pEnum);

	if (!SUCCEEDED(hr))
	{
		return -1; // device enumeration failed
	}

	if (pEnum == nullptr)
	{
		return -2;  // no video input device available
	}

	int status = 1;
	IMoniker *pMoniker = NULL;

	while (pEnum->Next(1, &pMoniker, NULL) == S_OK)
	{
		LPOLESTR str;
		if (!SUCCEEDED(pMoniker->GetDisplayName(0, 0, &str))) {
			continue;
		}

		size_t numChars = 0;
		char cstr[1024];
		wcstombs_s(&numChars, cstr, str, 512);
		CoTaskMemFree(str);  // Free the memory allocated

		if (strcmp(devicePath, cstr) == 0)
		{
			hr = pMoniker->BindToObject(0, 0, IID_IBaseFilter, (void**)filter);
			status = SUCCEEDED(hr) ? 0: 2;
			break;
		}
	}

	pEnum->Release();
	return status;
}
