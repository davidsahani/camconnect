#pragma warning(push)
#pragma warning(disable : 4244)

#include <string>
#include <vector>
#define NOMINMAX
#include <Windows.h>
#include <limits>
#include <memory>

#include "shared_memory/shared.inl"
#include "driver_interface.h"

#ifdef _WIN64
#define GUID_OFFSET 0x10
#else
#define GUID_OFFSET 0x20
#endif

static const int MAX_CAPNUM = SharedImageMemory::MAX_CAPNUM;

static void rtrim(std::string& s) {
    s.erase(std::find_if(s.rbegin(), s.rend(), [](unsigned char ch) {
        return !std::isspace(ch) && !std::iscntrl(ch);
    }).base(), s.end());
}

static bool get_name(int num, std::string& str, std::string& dkey) {
    constexpr size_t key_size = 45;
    char key[key_size];
    // https://github.com/schellingb/UnityCapture/blob/fe461e8f/Source/UnityCaptureFilter.cpp#L39
    snprintf(key, key_size, "CLSID\\{5C2CD55C-92AD-4999-8666-912BD3E700%02X}", GUID_OFFSET + num + !!num); // 1 is reserved by the library
    DWORD size; // includes terminating null character(s)
    if (RegGetValueA(HKEY_CLASSES_ROOT, key, NULL, RRF_RT_REG_SZ, NULL, NULL, &size) != ERROR_SUCCESS)
        return false;
    str.resize(size - 1);
    if (RegGetValueA(HKEY_CLASSES_ROOT, key, NULL, RRF_RT_REG_SZ, NULL, str.data(), &size) != ERROR_SUCCESS)
        return false;
    rtrim(str);
    dkey = std::string(key);
    return true;
}

inline int invertImageBuffer(const uint8_t* src_argb, uint8_t* dst_argb, int width, int height);

std::vector<DeviceInfo> DriverInterface::GetDevices() {
    std::vector<DeviceInfo> deviceNames;

    for (int CapNum = 0; CapNum < MAX_CAPNUM; CapNum++) {
        std::string deviceName, deviceKey;
        if (get_name(CapNum, deviceName, deviceKey)) {
            deviceNames.push_back(DeviceInfo{deviceName, deviceKey});
        }
    }
    return deviceNames;
}

int DriverInterface::SetDevice(const std::string& devicePath) {
    int CapNum;
    bool found = false;

    for (CapNum = 0; CapNum < MAX_CAPNUM; CapNum++) {
        std::string dName, dkey;
        if (get_name(CapNum, dName, dkey) && dkey == devicePath) {
            found = true;
            break;
        }
    }

    if (!found)
        return 1; // device not found.

    if (shm_ != nullptr)
        shm_ = nullptr;

    shm_ = std::make_unique<SharedImageMemory>(CapNum);
    return 0; // success
}

void DriverInterface::DestroyDevice() {
    if (shm_ != nullptr) {
        shm_ = nullptr;
    }
}

int DriverInterface::SendBuffer(const uint8_t *buffer, int width, int height) {
    if (shm_ == nullptr) {
        return -1;
    }

    if (!shm_->SendIsReady()) {
        // happens when no app is capturing the camera yet
        return -2;
    }

    if (width != width_ || height != height_) {
        width_ = width, height_ = height;
        bufferSize_ = width_ * height_ * 4;
        delete[] outBuffer_;
        outBuffer_ = new uint8_t[bufferSize_];
    }

    invertImageBuffer(buffer, outBuffer_, width, height);

    const int stride = width_;
    constexpr SharedImageMemory::EFormat format = SharedImageMemory::FORMAT_UINT8;
    // Note: RESIZEMODE_LINEAR means nearest neighbor scaling.
    constexpr SharedImageMemory::EResizeMode resize_mode = SharedImageMemory::RESIZEMODE_LINEAR;
    constexpr SharedImageMemory::EMirrorMode mirror_mode = SharedImageMemory::MIRRORMODE_DISABLED;
    // Keep showing last received frame after stopping while receiving app is still capturing.
    constexpr int timeout = std::numeric_limits<int>::max() - SharedImageMemory::RECEIVE_MAX_WAIT;
    return shm_->Send(width, height, stride, bufferSize_, format, resize_mode, mirror_mode, timeout, outBuffer_);
}

// Static variable initializations
int DriverInterface::width_ = 1280;
int DriverInterface::height_ = 720;
DWORD DriverInterface::bufferSize_ = width_ * height_ * 4;
uint8_t* DriverInterface::outBuffer_ = new uint8_t[bufferSize_];
std::unique_ptr<SharedImageMemory> DriverInterface::shm_ = nullptr;

/**
 * @brief Inverts the orientation of a BGRA image buffer horizontally.
 */
inline int invertImageBuffer(
    const uint8_t* src_argb,
    uint8_t* dst_argb,
    int width,
    int height
) {
    if (!src_argb || !dst_argb || width <= 0 || height == 0) {
        return -1;
    }
    const int stride = width * 4;
    int src_stride_argb = stride;
    // Invert the image.
    src_argb = src_argb + (height - 1) * src_stride_argb;
    src_stride_argb = -src_stride_argb;

    // Mirror plane
    for (int y = 0; y < height; ++y) {
        const uint32_t* src32 = (const uint32_t*)(src_argb);
        uint32_t* dst32 = (uint32_t*)(dst_argb);
        src32 += width - 1;
        for (int x = 0; x < width - 1; x += 2) {
            dst32[x] = src32[0];
            dst32[x + 1] = src32[-1];
            src32 -= 2;
        }
        if (width & 1) {
            dst32[width - 1] = src32[0];
        }
        dst_argb += stride;
        src_argb += src_stride_argb;
    }
    return 0;
}