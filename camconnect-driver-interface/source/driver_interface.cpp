#include "common.h"
#include "device.h"
#include "device_enumerator.h"
#include "driver_interface.h"

Device* g_activeDevice = NULL;
bool g_COM_Initialized = false;

bool _InitializeCOM()
{
    if (!g_COM_Initialized) {
        if (!SUCCEEDED(CoInitializeEx(NULL, COINIT_APARTMENTTHREADED))) {
            return false;  // COINIT_APARTMENTTHREADED failed
        }
        else {
            g_COM_Initialized = true;
        }
    }
    return true;
}


namespace DriverInterface {

int GetDevices(std::vector<DeviceInfo>& devicesInfo) {    
    if (!_InitializeCOM()) {
        return -1;  // COM initialization failed
    }
    return EnumerateDevices(devicesInfo);
}

int SetDevice(const std::string& devicePath) {
    DestroyDevice();

    if (!_InitializeCOM()) {
        return -3;  // COM initialization failed
    }

    IBaseFilter* filter = NULL;
    int status = GetFilter(devicePath, &filter);
    if (status || filter == NULL) {
        return status;
    }

    g_activeDevice = new Device(filter);
    status = g_activeDevice->Init();

    if (status) {
        delete g_activeDevice;
        g_activeDevice = NULL;
        return status + 2;
    }

    return status;  // success    
}

void DestroyDevice() {
    if (g_activeDevice != NULL) {
        delete g_activeDevice;
        g_activeDevice = NULL;
    }
}

void Release() {
    if (g_activeDevice != NULL) {
        delete g_activeDevice;
        g_activeDevice = NULL;
    }
    if (g_COM_Initialized) {
        CoUninitialize();
        g_COM_Initialized = false;
    }
}

int SetBuffer(PVOID data, const DWORD &dataLength) noexcept {
    if (g_activeDevice == NULL) {
        return -1;  // no active device
    }

    return g_activeDevice->SetData(data, dataLength);
}

}  // namespace DriverInterface
