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
     * @brief Start the video processing thread.
     */
    static void Start();

    /**
     * @brief Stop the video processing thread.
     */
    static void Stop();

    /**
     * @brief Add a task to the processing queue.
     * 
     * @param task The VideoProcessingTask to add.
     */
    static void AddTask(const VideoProcessingTask& task);

    /**
     * @brief Set the callback function to handle errors.
     * 
     * @param callback The callback function for error handling.
     */
    static void SetCallback(ErrorCallback callback);

private:
    /**
     * @brief The main loop of the processing thread.
     */
    static void ProcessingLoop();
};

}  // namespace driver_interface

#endif // DRIVER_INTERFACE_VIDEO_PROCESSING_THREAD_H