#include "device.h"

const GUID GUID_PROP_CLASS = { PROP_GUID };

Device::Device(IBaseFilter* filter)
	: filter(filter), propertySet(NULL)
{
}

Device::~Device()
{
	if (propertySet != NULL)
	{
		propertySet->Release();
	}

	filter->Release();
}

int Device::Init() noexcept
{
	HRESULT hr = filter->QueryInterface(IID_PPV_ARGS(&propertySet));
	if (!SUCCEEDED(hr)) 
	{
		return 1;  // QueryInterface failed
	}

	DWORD supportFlags = 0;
	hr = propertySet->QuerySupported(GUID_PROP_CLASS, PROP_DATA_ID, &supportFlags);
	if (!SUCCEEDED(hr)) 
	{
		return 2;  // QuerySupported failed
	}

	if ((supportFlags & KSPROPERTY_SUPPORT_SET) != KSPROPERTY_SUPPORT_SET)
	{
		return 3;  // device does not support property setting
	}

	return 0;  // success
}

int Device::SetData(PVOID dataPointer, const DWORD& dataLength) const noexcept
{
	const HRESULT hr = propertySet->Set(GUID_PROP_CLASS,
		PROP_DATA_ID, NULL, 0, dataPointer, dataLength);

	return !SUCCEEDED(hr);	// 0 success, 1 failure
}