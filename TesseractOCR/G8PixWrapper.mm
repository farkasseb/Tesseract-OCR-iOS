#import "G8PixWrapper.h"
#import <Leptonica/allheaders.h>

namespace g8 {

PixWrapper::PixWrapper(Pix* pix) noexcept : pix_(pix) {
    // Initialize with provided Pix pointer (can be nullptr)
}

PixWrapper::~PixWrapper() {
    reset();
}

PixWrapper::PixWrapper(PixWrapper&& other) noexcept : pix_(other.pix_) {
    // Take ownership of the Pix pointer and null out the source
    other.pix_ = nullptr;
}

PixWrapper& PixWrapper::operator=(PixWrapper&& other) noexcept {
    if (this != &other) {  // Prevent self-assignment
        reset(other.pix_); // Clean up existing and take new pointer
        other.pix_ = nullptr; // Null out source pointer
    }
    return *this;
}

Pix* PixWrapper::get() const noexcept {
    return pix_;
}

PixWrapper::operator bool() const noexcept {
    return pix_ != nullptr;
}

Pix* PixWrapper::release() noexcept {
    Pix* temp = pix_;
    pix_ = nullptr;
    return temp;
}

void PixWrapper::reset(Pix* pix) noexcept {
    if (pix_ != pix) {  // Only cleanup if different pointer
        if (pix_) {
            pixDestroy(&pix_); // Leptonica's cleanup function
        }
        pix_ = pix;
    }
}

} // namespace g8
