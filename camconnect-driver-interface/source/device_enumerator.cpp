#include <comutil.h>
#pragma comment(lib, "comsuppw.lib")

#include "device_enumerator.h"

/**
 * @brief Creates Device Enumerator for the specified category.
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

int EnumerateDevices(std::vector<DeviceInfo>& devicesInfo)
{
	IEnumMoniker* pEnum;
	if (!SUCCEEDED(CreateDeviceEnumerator(CLSID_VideoInputDeviceCategory, &pEnum)))
	{
		return 1;  // device enumeration failed
	}

	if (pEnum == nullptr)
	{
		return 0;  // no video input device available
	}

	IMoniker* pMoniker = nullptr;

	while (pEnum->Next(1, &pMoniker, nullptr) == S_OK)
	{
		DeviceInfo deviceInfo;

		// Get display name (device path)
		LPOLESTR str;
		if (SUCCEEDED(pMoniker->GetDisplayName(0, 0, &str))) {
			size_t numChars = 0;
			char cstr[1024];
			wcstombs_s(&numChars, cstr, str, 512);
			CoTaskMemFree(str);  // Free the memory allocated

			deviceInfo.devicePath = cstr;
		}

		// Get device friendly name
		IPropertyBag* pPropBag;
		if (SUCCEEDED(pMoniker->BindToStorage(nullptr, nullptr, IID_PPV_ARGS(&pPropBag))))
		{
			VARIANT var;
			VariantInit(&var);

			if (SUCCEEDED(pPropBag->Read(L"FriendlyName", &var, nullptr)))
			{
				if (var.vt == VT_BSTR)
				{
					deviceInfo.friendlyName = _com_util::ConvertBSTRToString(var.bstrVal);
				}
				VariantClear(&var);
			}

			pPropBag->Release();
		}

		devicesInfo.push_back(deviceInfo);
	}

	pEnum->Release();
	return 0;  // success.
}

int GetFilter(const std::string& devicePath, IBaseFilter** filter)
{
	IEnumMoniker* pEnum;
	if (!SUCCEEDED(CreateDeviceEnumerator(CLSID_VideoInputDeviceCategory, &pEnum)))
	{
		return -1;  // device enumeration failed
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

		if (strcmp(devicePath.c_str(), cstr) == 0)
		{
			auto hr = pMoniker->BindToObject(0, 0, IID_IBaseFilter, (void**)filter);
			status = SUCCEEDED(hr) ? 0: 2;
			break;
		}
	}

	pEnum->Release();
	return status;
}