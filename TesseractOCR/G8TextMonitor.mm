#import "G8TextMonitor.h"
#import <Tesseract/baseapi.h>
#import <Tesseract/ocrclass.h>
#import <stdexcept>

namespace g8 {

TextMonitor::TextMonitor(G8CancelationCallback cancelFunc, void* userData): monitor_(new tesseract::ETEXT_DESC()) {
    if (!monitor_) {
        throw std::bad_alloc();
    }
    setCancelCallback(cancelFunc, userData);
}

TextMonitor::~TextMonitor() {
    delete monitor_;
}

TextMonitor::TextMonitor(TextMonitor&& other) noexcept: monitor_(other.monitor_) {
    // Take ownership and null out source
    other.monitor_ = nullptr;
}

TextMonitor& TextMonitor::operator=(TextMonitor&& other) noexcept {
    if (this != &other) {
        // Clean up existing
        delete monitor_;

        // Take ownership from other
        monitor_ = other.monitor_;
        other.monitor_ = nullptr;
    }
    return *this;
}

tesseract::ETEXT_DESC* TextMonitor::get() const noexcept {
    return monitor_;
}

int TextMonitor::getProgress() const noexcept {
    return monitor_ ? monitor_->progress : 0;
}

void TextMonitor::setCancelCallback(G8CancelationCallback cancelFunc, void* userData) noexcept {
    if (monitor_) {
        monitor_->cancel = cancelFunc;
        monitor_->cancel_this = userData;
    }
}

void TextMonitor::setDeadline(int deadline_msecs) noexcept {
    if (monitor_) {
        monitor_->set_deadline_msecs(deadline_msecs);
    }
}

} // namespace g8
