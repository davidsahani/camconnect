#ifndef DRIVER_INTERFACE_H
#define DRIVER_INTERFACE_H

#include <string>
#include <vector>
#include <memory>

struct SharedImageMemory; // Forward declaration

/**
 * @brief Represents information about a device.
 */
struct DeviceInfo
{
    std::string friendlyName;  // A user-friendly name for the device.
    std::string devicePath;    // The path of the device.
};

class DriverInterface {
private:
    static int width_;
    static int height_;
    static uint8_t* outBuffer_;
    static unsigned long bufferSize_;
    static std::unique_ptr<SharedImageMemory> shm_;

public:
    /**
     * @brief Get installed UnityCapture device infos.
     */
    static std::vector<DeviceInfo> GetDevices();

    /**
     * @brief Set the active device handle.
     *
     * @param[in] devicePath The device path to set as the active device.
     *
     * @return 0: Success,
     * 1: Failure (device not found).
    */
    static int SetDevice(const std::string& devicePath);

    /**
     * @brief Destroy the active device handle.
     */
    static void DestroyDevice();

    /**
     * @brief Send frame buffer to vcam.
     *
     * @param[in] buffer BGRA frame buffer.
     * @param[in] width Width of frame buffer.
     * @param[in] height Height of frame buffer.
     *
     * @return 0: Success, 1: Failure.
     * -1: Failure (no active device).
     */
    static int SendBuffer(const uint8_t* buffer, int width, int height);
};

#endif // DRIVER_INTERFACE_H
