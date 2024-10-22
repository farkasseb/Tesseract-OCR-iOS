# Existing path variables
TESSERACT_ROOT = $(shell pwd)
LEPTON_NAME = leptonica
LEPTON_SRC = $(TESSERACT_ROOT)/$(LEPTON_NAME)

# New Tesseract variables
TESSERACT_NAME = tesseract-ocr
TESSERACT_SRC = $(TESSERACT_ROOT)/$(TESSERACT_NAME)

# Build variables for Leptonica and Tesseract
ARCHS = arm64 arm64-simulator x86_64-simulator
BUILD_DIR = $(TESSERACT_ROOT)/build/
INSTALL_DIR = $(TESSERACT_ROOT)/install/
LEPT_BUILD_DIR = $(TESSERACT_ROOT)/build/leptonica
LEPT_INSTALL_DIR = $(TESSERACT_ROOT)/install/leptonica
TESS_BUILD_DIR = $(TESSERACT_ROOT)/build/tesseract
TESS_INSTALL_DIR = $(TESSERACT_ROOT)/install/tesseract
FRAMEWORK_DIR = $(TESSERACT_ROOT)/xcframework

# SDK paths
SDK_IPHONEOS_PATH=$(shell xcrun --sdk iphoneos --show-sdk-path)
SDK_IPHONESIMULATOR_PATH=$(shell xcrun --sdk iphonesimulator --show-sdk-path)

# Common flags
COMMON_FLAGS = -pipe -no-cpp-precomp -miphoneos-version-min=15.0 -O2

# Targets
.PHONY: all clean leptonica tesseract

all: leptonica tesseract

# Leptonica target
leptonica: $(FRAMEWORK_DIR)/Leptonica.xcframework

$(FRAMEWORK_DIR)/Leptonica.xcframework: $(LEPT_INSTALL_DIR)/ios/lib/libleptonica.a $(LEPT_INSTALL_DIR)/simulator/lib/libleptonica.a
	mkdir -p $(FRAMEWORK_DIR)
	rm -Rf $(FRAMEWORK_DIR)/Leptonica.xcframework
	xcodebuild -create-xcframework \
		-library $(LEPT_INSTALL_DIR)/ios/lib/libleptonica.a \
		-headers $(LEPT_INSTALL_DIR)/ios/include \
		-library $(LEPT_INSTALL_DIR)/simulator/lib/libleptonica.a \
		-headers $(LEPT_INSTALL_DIR)/simulator/include \
		-output $(FRAMEWORK_DIR)/Leptonica.xcframework

$(LEPT_INSTALL_DIR)/ios/lib/libleptonica.a $(LEPT_INSTALL_DIR)/simulator/lib/libleptonica.a: $(LEPTON_SRC)/configure
	@echo "Building for architectures: $(ARCHS)"
	for arch in $(ARCHS); do \
		echo "Building for $$arch"; \
		mkdir -p $(LEPT_BUILD_DIR)/$$arch; \
		cd $(LEPT_BUILD_DIR)/$$arch; \
		if [ $$arch = "arm64-simulator" ] || [ $$arch = "x86_64-simulator" ]; then \
			export SDKROOT=$(SDK_IPHONESIMULATOR_PATH); \
			export HOST=$${arch%-simulator}-apple-darwin; \
			export CFLAGS="$(COMMON_FLAGS) -arch $${arch%-simulator} -isysroot $$SDKROOT -target $${arch%-simulator}-apple-ios15.0-simulator"; \
			export INSTALL_DIR=$(LEPT_INSTALL_DIR)/simulator; \
		else \
			export SDKROOT=$(SDK_IPHONEOS_PATH); \
			export HOST=$$arch-apple-darwin; \
			export CFLAGS="$(COMMON_FLAGS) -arch $$arch -isysroot $$SDKROOT -target $$arch-apple-ios15.0"; \
			export INSTALL_DIR=$(LEPT_INSTALL_DIR)/ios; \
		fi; \
		export CPPFLAGS=$$CFLAGS; \
		export LDFLAGS="-arch $${arch%-simulator} -L$$SDKROOT/usr/lib/"; \
		echo "Configuring for $$arch"; \
		$(LEPTON_SRC)/configure --host=$$HOST --prefix=$$INSTALL_DIR --enable-shared=no --disable-programs --without-zlib --without-libpng --without-jpeg --without-giflib --without-libtiff --without-libwebp --without-libopenjpeg || exit 1; \
		echo "Building for $$arch"; \
		make -j8 || exit 1; \
		echo "Installing for $$arch"; \
		make install || exit 1; \
	done
	mkdir -p $(LEPT_INSTALL_DIR)/simulator/lib
	xcrun lipo -create $(LEPT_BUILD_DIR)/arm64-simulator/src/.libs/libleptonica.a $(LEPT_BUILD_DIR)/x86_64-simulator/src/.libs/libleptonica.a -output $(LEPT_INSTALL_DIR)/simulator/lib/libleptonica.a

# Tesseract target
tesseract: $(FRAMEWORK_DIR)/Tesseract.xcframework

$(FRAMEWORK_DIR)/Tesseract.xcframework: $(TESS_INSTALL_DIR)/ios/lib/libtesseract.a $(TESS_INSTALL_DIR)/simulator/lib/libtesseract.a
	mkdir -p $(FRAMEWORK_DIR)
	rm -Rf $(FRAMEWORK_DIR)/Tesseract.xcframework
	xcodebuild -create-xcframework \
		-library $(TESS_INSTALL_DIR)/ios/lib/libtesseract.a \
		-headers $(TESS_INSTALL_DIR)/ios/include \
		-library $(TESS_INSTALL_DIR)/simulator/lib/libtesseract.a \
		-headers $(TESS_INSTALL_DIR)/simulator/include \
		-output $(FRAMEWORK_DIR)/Tesseract.xcframework

$(TESS_INSTALL_DIR)/ios/lib/libtesseract.a $(TESS_INSTALL_DIR)/simulator/lib/libtesseract.a: $(TESSERACT_SRC)/configure $(LEPT_INSTALL_DIR)/ios/lib/libleptonica.a
	@echo "Building Tesseract for architectures: $(ARCHS)"
	for arch in $(ARCHS); do \
		echo "Building Tesseract for $$arch"; \
		mkdir -p $(TESS_BUILD_DIR)/$$arch; \
		cd $(TESS_BUILD_DIR)/$$arch; \
		if [ $$arch = "arm64-simulator" ] || [ $$arch = "x86_64-simulator" ]; then \
			export SDKROOT=$(SDK_IPHONESIMULATOR_PATH); \
			export HOST=$${arch%-simulator}-apple-darwin; \
			export CFLAGS="$(COMMON_FLAGS) -arch $${arch%-simulator} -isysroot $$SDKROOT -target $${arch%-simulator}-apple-ios15.0-simulator"; \
			export INSTALL_DIR=$(TESS_INSTALL_DIR)/simulator; \
			export LEPTONICA_LIBS="-L$(LEPT_INSTALL_DIR)/simulator/lib -lleptonica"; \
			export LEPTONICA_CFLAGS="-I$(LEPT_INSTALL_DIR)/simulator/include"; \
		else \
			export SDKROOT=$(SDK_IPHONEOS_PATH); \
			export HOST=$$arch-apple-darwin; \
			export CFLAGS="$(COMMON_FLAGS) -arch $$arch -isysroot $$SDKROOT -target $$arch-apple-ios15.0"; \
			export INSTALL_DIR=$(TESS_INSTALL_DIR)/ios; \
			export LEPTONICA_LIBS="-L$(LEPT_INSTALL_DIR)/ios/lib -lleptonica"; \
			export LEPTONICA_CFLAGS="-I$(LEPT_INSTALL_DIR)/ios/include"; \
		fi; \
		export CPPFLAGS=$$CFLAGS; \
		export LDFLAGS="-arch $${arch%-simulator} -L$$SDKROOT/usr/lib/"; \
		echo "Configuring Tesseract for $$arch"; \
		$(TESSERACT_SRC)/configure --host=$$HOST --prefix=$$INSTALL_DIR --disable-shared --disable-graphics --disable-legacy --disable-oem --disable-doc --disable-openmp --with-pic --with-extra-libraries=$$SDKROOT/usr/lib LEPTONICA_LIBS="$$LEPTONICA_LIBS" LEPTONICA_CFLAGS="$$LEPTONICA_CFLAGS" || exit 1; \
		echo "Building Tesseract for $$arch"; \
		make -j8 || exit 1; \
		echo "Installing Tesseract for $$arch"; \
		make install || exit 1; \
	done
	mkdir -p $(TESS_INSTALL_DIR)/simulator/lib
	xcrun lipo -create $(TESS_BUILD_DIR)/arm64-simulator/src/.libs/libtesseract.a $(TESS_BUILD_DIR)/x86_64-simulator/src/.libs/libtesseract.a -output $(TESS_INSTALL_DIR)/simulator/lib/libtesseract.a

clean:
	rm -Rf $(BUILD_DIR)
	rm -Rf $(INSTALL_DIR)
