#include "driver_interface.h"
#include "driver_interface_video_proc_thread.h"

namespace driver_interface {

std::mutex mutex_;
std::condition_variable condition_;
std::thread processing_thread_;
std::queue<VideoProcessingTask> task_queue_;
bool stop_thread_ = false;
int status_ = 2;
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
        status_ = 2; // reset status for error propagation
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

        // Send frame buffer to virtual camera driver using DriverInterface.
        const int status = DriverInterface::SendBuffer(task.buffer, static_cast<int>(task.width), static_cast<int>(task.height));

        if (status != status_ && error_callback_) {
            switch (status)
            {
            case -1:
                error_callback_("DriverInterface::SetBuffer Error: No active device.");
                break;
            case 0:
                error_callback_("DriverInterface::SetBuffer Error: Buffer too large.");
                break;
            case 2:
                error_callback_("");  // on success.
                break;
            default:
                break;
            }
            status_ = status;
        }
    }
}

}  // namespace driver_interface