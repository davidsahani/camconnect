#ifndef DRIVER_INTERFACE_VIDEO_PROCESSING_THREAD_H
#define DRIVER_INTERFACE_VIDEO_PROCESSING_THREAD_H

#include <thread>
#include <queue>
#include <mutex>
#include <condition_variable>
#include <cstdint>
#include <functional>

namespace driver_interface {
using ErrorCallback = std::function<void(const std::string&)>;

typedef struct {
    uint8_t* buffer;
    size_t width;
    size_t height;
} VideoProcessingTask;

class VideoProcessingThread {
public:
    /**
     * @brief Starts the video processing thread.
     */
    static void Start();

    /**
     * @brief Stops the video processing thread.
     */
    static void Stop();

    /**
     * @brief Adds a task to the processing queue.
     * 
     * @param task The VideoProcessingTask to add.
     */
    static void AddTask(const VideoProcessingTask& task);

    /**
     * @brief Sets the callback function to handle errors.
     * 
     * @param callback The callback function for error handling.
     */
    static void SetCallback(ErrorCallback callback);

private:
    /**
     * @brief The main loop of the processing thread.
     */
    static void ProcessingLoop();

    /**
     * @brief Convert BGRA pixels to RGB pixels.
     * 
     * @param bgraSrcBuffer Pointer to the source BGRA buffer.
     * @param rgbDstBuffer Pointer to the destination RGB buffer.
     * @param srcWidth Width of source buffer.
     * @param srcHeight Height of source buffer.
     */
    static void convertBGRAtoRGB(const uint8_t* bgraSrcBuffer,
        uint8_t* rgbDstBuffer, const size_t& srcWidth, const size_t& srcHeight
    );

    /**
     * @brief Resize BGRA source buffer to fit desired converted destination RGB buffer size.
     *
     * @param bgraSrcBuffer Pointer to source BGRA buffer.
     * @param srcWidth Width of source buffer.
     * @param srcHeight Height of source buffer.
     * @param rgbDstBuffer Pointer to destination RGB buffer.
     * @param dstWidth Desired width of destination buffer.
     * @param dstHeight Desired height of destination buffer.
     * 
     * @note Aspect ratio is not preserved during resizing.
     */
    static void resizeAndConvertBGRAtoRGB(
        const uint8_t* bgraSrcBuffer, const size_t& srcWidth, const size_t& srcHeight,
        uint8_t* rgbDstBuffer, const size_t& dstWidth, const size_t& dstHeight
    );

    /**
     * @brief Resize RGB source buffer to fit desired
     * destination buffer size preserving aspect ratio.
     *
     * @param srcBuffer Pointer to source buffer.
     * @param srcWidth Width of source buffer.
     * @param srcHeight Height of source buffer.
     * @param dstBuffer Pointer to destination buffer.
     * @param dstWidth Desired width of destination buffer.
     * @param dstHeight Desired height of destination buffer.
     * 
     * @note To maintain the aspect ratio, a new destination matching aspect ratio
     * resolution is created and pixels are exacted to match this resolution.
     */
    static void resizeAndConvertBGRAtoRGBwithAspectRatio(
        const uint8_t* bgraSrcBuffer, const size_t& srcWidth, const size_t& srcHeight,
        uint8_t* rgbDstBuffer, const size_t& dstWidth, const size_t& dstHeight
    );
};

inline bool isEqual(const float& a, const float& b) {
    constexpr float tolerance = 0.1F;
    return fabs(a - b) <= tolerance;
}

}  // namespace driver_interface

#endif // DRIVER_INTERFACE_VIDEO_PROCESSING_THREAD_H