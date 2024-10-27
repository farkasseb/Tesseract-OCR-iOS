#ifndef G8TextMonitor_h
#define G8TextMonitor_h

#import <Foundation/Foundation.h>

// Forward declarations to avoid exposing Tesseract internals
namespace tesseract {
class ETEXT_DESC;
}

/**
 * Type definition for cancellation callback function.
 * @param cancel_this User data pointer passed to callback
 * @param words Number of words processed
 * @return true if recognition should be cancelled
 */
typedef bool (*G8CancelationCallback)(void* cancel_this, int words);

namespace g8 {

/**
 * RAII wrapper for Tesseract's ETEXT_DESC monitor.
 * Manages the lifecycle of progress/cancellation monitor for OCR operations.
 *
 * Usage example:
 * @code
 * {
 *     g8::TextMonitor monitor(cancelCallback, userData);
 *     // Use monitor.get() to access raw ETEXT_DESC pointer
 *     // Monitor is automatically destroyed when scope ends
 * }
 * @endcode
 */
class TextMonitor final {
public:
    /**
     * Constructs a TextMonitor with specified callback and user data.
     * @param cancelFunc Callback function for cancellation checks
     * @param userData User data pointer passed to callback
     * @throw std::bad_alloc if memory allocation fails
     */
    TextMonitor(G8CancelationCallback cancelFunc = nullptr, void* userData = nullptr);

    /**
     * Destroys the monitor and frees associated resources.
     */
    ~TextMonitor();

    /**
     * Copy construction is disabled to ensure unique ownership.
     */
    TextMonitor(const TextMonitor&) = delete;

    /**
     * Copy assignment is disabled to ensure unique ownership.
     */
    TextMonitor& operator=(const TextMonitor&) = delete;

    /**
     * Move constructor enables transfer of ownership.
     * @param other TextMonitor to move from
     */
    TextMonitor(TextMonitor&& other) noexcept;

    /**
     * Move assignment enables transfer of ownership.
     * @param other TextMonitor to move from
     * @return Reference to this object
     */
    TextMonitor& operator=(TextMonitor&& other) noexcept;

    /**
     * Access the underlying ETEXT_DESC pointer.
     * @return Raw ETEXT_DESC pointer (never nullptr after construction)
     */
    tesseract::ETEXT_DESC* get() const noexcept;

    /**
     * Get the current progress (0-100).
     * @return Progress percentage
     */
    int getProgress() const noexcept;

    /**
     * Set the cancellation callback function.
     * @param cancelFunc New callback function
     * @param userData New user data pointer
     */
    void setCancelCallback(G8CancelationCallback cancelFunc, void* userData = nullptr) noexcept;

    /**
     * Set deadline for OCR operation.
     * @param deadline_msecs Maximum time in milliseconds
     */
    void setDeadline(int deadline_msecs) noexcept;

private:
    tesseract::ETEXT_DESC* monitor_; // The wrapped ETEXT_DESC pointer
};

} // namespace g8

#endif /* G8TextMonitor_h */
