#ifndef G8PixWrapper_h
#define G8PixWrapper_h

#import <Foundation/Foundation.h>

// Forward declare Pix struct to avoid including Leptonica headers in header
struct Pix;

namespace g8 {

/**
 * RAII wrapper for Leptonica's Pix structure.
 * Ensures automatic cleanup of Pix resources when the wrapper goes out of scope.
 *
 * Usage example:
 * @code
 * {
 *     g8::PixWrapper pix(somePixPointer);
 *     // Use pix.get() to access the raw Pix pointer
 *     // When scope ends, Pix is automatically destroyed
 * }
 * @endcode
 */
class PixWrapper final {
public:
    /**
     * Constructs a PixWrapper taking ownership of the provided Pix pointer.
     * @param pix Raw Pix pointer to wrap. Can be nullptr.
     * @note The wrapper takes ownership of the pointer and will destroy it.
     */
    explicit PixWrapper(Pix* pix = nullptr) noexcept;

    /**
     * Destroys the wrapped Pix object using Leptonica's pixDestroy.
     */
    ~PixWrapper();

    /**
     * Copy construction is disabled to ensure unique ownership.
     */
    PixWrapper(const PixWrapper&) = delete;

    /**
     * Copy assignment is disabled to ensure unique ownership.
     */
    PixWrapper& operator=(const PixWrapper&) = delete;

    /**
     * Move constructor enables transfer of ownership.
     * @param other PixWrapper to move from
     */
    PixWrapper(PixWrapper&& other) noexcept;

    /**
     * Move assignment enables transfer of ownership.
     * @param other PixWrapper to move from
     * @return Reference to this object
     */
    PixWrapper& operator=(PixWrapper&& other) noexcept;

    /**
     * Access the underlying Pix pointer.
     * @return Raw Pix pointer (may be nullptr)
     */
    Pix* get() const noexcept;

    /**
     * Check if wrapper contains a valid Pix pointer.
     * @return true if the wrapped pointer is not nullptr
     */
    explicit operator bool() const noexcept;

    /**
     * Release ownership of the Pix pointer without destroying it.
     * @return Raw Pix pointer that was being managed
     * @note Caller becomes responsible for memory management after release
     */
    Pix* release() noexcept;

    /**
     * Replace the managed Pix pointer with a new one.
     * @param pix New Pix pointer to manage
     * @note Previous Pix object (if any) is destroyed
     */
    void reset(Pix* pix = nullptr) noexcept;

private:
    Pix* pix_; // The wrapped Pix pointer
};

} // namespace g8

#endif /* G8PixWrapper_h */
