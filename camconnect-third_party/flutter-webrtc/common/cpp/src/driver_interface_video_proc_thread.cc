#include "driver_interface.h"
#include "driver_interface_video_proc_thread.h"

namespace driver_interface {

std::mutex mutex_;
std::condition_variable condition_;
std::thread processing_thread_;
std::queue<VideoProcessingTask> task_queue_;
bool stop_thread_ = false;

#define WIDTH 1280  // Camera supported width
#define HEIGHT 720  // Camera supported height
#define ASPECT_RATIO 1.78f  // WIDTH / HEIGHT
#define BUFFER_SIZE WIDTH * HEIGHT * 3

size_t prev_width_ = WIDTH;
size_t prev_height_ = HEIGHT;
bool has_same_aspect_ratio_ = true;
uint8_t rgb_buffer_[BUFFER_SIZE];

int status_ = 0;
ErrorCallback error_callback_;

void VideoProcessingThread::Start() {
    if (!processing_thread_.joinable()) {
        stop_thread_ = false;
        processing_thread_ = std::thread(ProcessingLoop);
    }
}

void VideoProcessingThread::Stop() {
    if (processing_thread_.joinable()) {
        stop_thread_ = true;
        condition_.notify_one();
        processing_thread_.join();
        status_ = 0; // reset status for error propagation
    }
}

void VideoProcessingThread::SetCallback(ErrorCallback callback) {
    error_callback_ = std::move(callback);
}

void VideoProcessingThread::AddTask(const VideoProcessingTask& task) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!stop_thread_) {
        task_queue_.push(task);
        condition_.notify_one();
    }
}

void VideoProcessingThread::ProcessingLoop() {
    while (!stop_thread_) {
        std::unique_lock<std::mutex> lock(mutex_);

        // Wait for a task to be added to the queue
        condition_.wait(lock, [] { return !task_queue_.empty() || stop_thread_; });

        // Check if the thread is being stopped
        if (stop_thread_) {
            break;
        }

        // Retrieve and process the task
        const VideoProcessingTask task = task_queue_.front();
        task_queue_.pop();

        lock.unlock();  // Release the lock after fetching task

        if (task.width == WIDTH && task.height == HEIGHT) {
            convertBGRAtoRGB(task.buffer, rgb_buffer_, WIDTH, HEIGHT);
 
        } else {
            if (task.width != prev_width_ || task.height != prev_height_) {
                prev_width_ = task.width, prev_height_ = task.height;
                const float aspect_ratio_ = static_cast<float>(task.width) / task.height;
                has_same_aspect_ratio_ = isEqual(aspect_ratio_, ASPECT_RATIO);
            }

            if (has_same_aspect_ratio_) {
                resizeAndConvertBGRAtoRGB(
                    task.buffer, task.width, task.height,  /* source buffer */
                    rgb_buffer_, WIDTH, HEIGHT             /* destination buffer */
                );
            } else {
                resizeAndConvertBGRAtoRGBwithAspectRatio(
                    task.buffer, task.width, task.height,  /* source buffer */
                    rgb_buffer_, WIDTH, HEIGHT             /* destination buffer */
                );
            }
        }

        // Set RGB buffer data for the virtual camera driver using DriverInterface.
        const int status = DriverInterface::SetBuffer(rgb_buffer_, BUFFER_SIZE);

        if (status != status_ && error_callback_) {
            status_ = status;
            error_callback_(status == 0 ? "":  // no error
                (status == -1) ?
                "DriverInterface::SetBuffer Error: No active device." :
                "DriverInterface::SetBuffer Error: Failed to set buffer."
            );
        }
    }
}

inline void VideoProcessingThread::convertBGRAtoRGB(const uint8_t* bgraSrcBuffer,
    uint8_t* rgbDstBuffer, const size_t& srcWidth, const size_t& srcHeight)
{
    for (uint32_t i = 0; i < srcWidth * srcHeight; ++i) {
        const uint32_t argbSrcIndex = i * 4;  // BGRA has 4 bytes per pixel
        const uint32_t rgbDestIndex = i * 3;  // RGB has 3 bytes per pixel

        // Extract RGB components from BGRA buffer
        const uint8_t blue = bgraSrcBuffer[argbSrcIndex];
        const uint8_t green = bgraSrcBuffer[argbSrcIndex + 1];
        const uint8_t red = bgraSrcBuffer[argbSrcIndex + 2];

        // Store RGB components into the RGB buffer
        rgbDstBuffer[rgbDestIndex] = red;
        rgbDstBuffer[rgbDestIndex + 1] = green;
        rgbDstBuffer[rgbDestIndex + 2] = blue;
    }
}

inline void VideoProcessingThread::resizeAndConvertBGRAtoRGB(
    const uint8_t* bgraSrcBuffer, const size_t& srcWidth, const size_t& srcHeight,
    uint8_t* rgbDstBuffer, const size_t& dstWidth, const size_t& dstHeight)
{
    const float scaleX = static_cast<float>(srcWidth) / dstWidth;
    const float scaleY = static_cast<float>(srcHeight) / dstHeight;

    for (size_t y = 0; y < dstHeight; ++y) {
        const size_t sourceY = static_cast<size_t>(y * scaleY);
        const size_t destOffset = y * dstWidth * 3;                // RGB has 3 bytes per pixel
        const size_t sourceOffset = sourceY * srcWidth * 4;        // BGRA has 4 bytes per pixel

        for (size_t x = 0; x < dstWidth; ++x) {
            const size_t sourceX = static_cast<size_t>(x * scaleX);
            const size_t destIndex = destOffset + x * 3;           // RGB has 3 bytes per pixel
            const size_t sourceIndex = sourceOffset + sourceX * 4; // BGRA has 4 bytes per pixel

            // Extract RGB components from BGRA buffer
            const uint8_t blue = bgraSrcBuffer[sourceIndex];
            const uint8_t green = bgraSrcBuffer[sourceIndex + 1];
            const uint8_t red = bgraSrcBuffer[sourceIndex + 2];

            // Store RGB components into the RGB buffer
            rgbDstBuffer[destIndex] = red;
            rgbDstBuffer[destIndex + 1] = green;
            rgbDstBuffer[destIndex + 2] = blue;
        }
    }
}

inline void VideoProcessingThread::resizeAndConvertBGRAtoRGBwithAspectRatio(
    const uint8_t* bgraSrcBuffer, const size_t& srcWidth, const size_t& srcHeight,
    uint8_t* rgbDstBuffer, const size_t& dstWidth, const size_t& dstHeight)
{
    const float scaleX = static_cast<float>(srcWidth) / dstWidth;
    const float scaleY = static_cast<float>(srcHeight) / dstHeight;
    const float& scale = (scaleX < scaleY) ? scaleX : scaleY;

    const size_t adjustedWidth = static_cast<size_t>(dstWidth * scale);
    const size_t adjustedHeight = static_cast<size_t>(dstHeight * scale);

    const float adjustedScaleX = static_cast<float>(adjustedWidth) / dstWidth;
    const float adjustedScaleY = static_cast<float>(adjustedHeight) / dstHeight;

    for (size_t y = 0; y < dstHeight; ++y) {
        const size_t sourceY = static_cast<size_t>(y * adjustedScaleY);
        const size_t destOffset = y * dstWidth * 3;                // RGB has 3 bytes per pixel
        const size_t sourceOffset = sourceY * srcWidth * 4;        // BGRA has 4 bytes per pixel

        for (size_t x = 0; x < dstWidth; ++x) {
            const size_t sourceX = static_cast<size_t>(x * adjustedScaleX);
            const size_t destIndex = destOffset + x * 3;           // RGB has 3 bytes per pixel
            const size_t sourceIndex = sourceOffset + sourceX * 4; // BGRA has 4 bytes per pixel

            // Extract RGB components from BGRA buffer
            const uint8_t blue = bgraSrcBuffer[sourceIndex];
            const uint8_t green = bgraSrcBuffer[sourceIndex + 1];
            const uint8_t red = bgraSrcBuffer[sourceIndex + 2];

            // Store RGB components into the RGB buffer
            rgbDstBuffer[destIndex] = red;
            rgbDstBuffer[destIndex + 1] = green;
            rgbDstBuffer[destIndex + 2] = blue;
        }
    }
}

}  // namespace driver_interface