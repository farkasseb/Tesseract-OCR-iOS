# Existing path variables
TESSERACT_ROOT = $(shell pwd)
LEPTON_NAME = leptonica
LEPTON_SRC = $(TESSERACT_ROOT)/$(LEPTON_NAME)
TESSERACT_NAME = tesseract-ocr
TESSERACT_SRC = $(TESSERACT_ROOT)/$(TESSERACT_NAME)
JPEG_SRC_NAME = jpegsrc.v9a
JPEG_DIR_NAME = jpeg-9a
JPEG_SRC = $(TESSERACT_ROOT)/$(JPEG_DIR_NAME)

# Build variables
ARCHS = arm64 arm64-simulator x86_64-simulator
BUILD_DIR = $(TESSERACT_ROOT)/build/
INSTALL_DIR = $(TESSERACT_ROOT)/install/
LEPT_BUILD_DIR = $(TESSERACT_ROOT)/build/leptonica
LEPT_INSTALL_DIR = $(TESSERACT_ROOT)/install/leptonica
TESS_BUILD_DIR = $(TESSERACT_ROOT)/build/tesseract
TESS_INSTALL_DIR = $(TESSERACT_ROOT)/install/tesseract
JPEG_BUILD_DIR = $(TESSERACT_ROOT)/build/jpeg
JPEG_INSTALL_DIR = $(TESSERACT_ROOT)/install/jpeg
FRAMEWORK_DIR = $(TESSERACT_ROOT)/xcframework

# SDK paths
SDK_IPHONEOS_PATH=$(shell xcrun --sdk iphoneos --show-sdk-path)
SDK_IPHONESIMULATOR_PATH=$(shell xcrun --sdk iphonesimulator --show-sdk-path)

# Common flags for all builds
COMMON_FLAGS = -pipe -no-cpp-precomp -miphoneos-version-min=15.0 -O2

# Common exports for all builds
COMMON_EXPORTS = \
	export CC="clang"; \
	export CXX="clang++"; \
	export PKG_CONFIG_PATH=""; \
	export PKG_CONFIG_LIBDIR=""

# Simulator-specific flags
define SIMULATOR_FLAGS
	export SDKROOT=$(SDK_IPHONESIMULATOR_PATH); \
	export HOST=$${arch%%-simulator}-apple-darwin; \
	export CFLAGS="$(COMMON_FLAGS) -arch $${arch%%-simulator} -isysroot $$SDKROOT -target $${arch%%-simulator}-apple-ios15.0-simulator"; \
	export LDFLAGS="-arch $${arch%%-simulator} -L$$SDKROOT/usr/lib/"
endef

# Device-specific flags
define DEVICE_FLAGS
	export SDKROOT=$(SDK_IPHONEOS_PATH); \
	export HOST=$$arch-apple-darwin; \
	export CFLAGS="$(COMMON_FLAGS) -arch $$arch -isysroot $$SDKROOT -target $$arch-apple-ios15.0"; \
	export LDFLAGS="-arch $$arch -L$$SDKROOT/usr/lib/"
endef

# Targets
.PHONY: all leptonica tesseract autogen-tesseract xcframeworks leptonica-xcframework tesseract-xcframework clean clean-leptonica clean-tesseract distclean-tesseract jpeg clean-jpeg jpeg-xcframework

all: jpeg leptonica tesseract

# JPEG target
jpeg: clean-jpeg $(JPEG_SRC)/configure
	@echo "Building jpeg for architectures: $(ARCHS)"
	for arch in $(ARCHS); do \
		echo "Building jpeg for $$arch"; \
		mkdir -p $(JPEG_BUILD_DIR)/$$arch; \
		cd $(JPEG_BUILD_DIR)/$$arch; \
		$(COMMON_EXPORTS); \
		if [ $$arch = "arm64-simulator" ] || [ $$arch = "x86_64-simulator" ]; then \
			export SDKROOT=$(SDK_IPHONESIMULATOR_PATH); \
			if [ $$arch = "arm64-simulator" ]; then \
				export HOST=aarch64-apple-darwin; \
			else \
				export HOST=x86_64-apple-darwin; \
			fi; \
			export CFLAGS="$(COMMON_FLAGS) -arch $${arch%%-simulator} -isysroot $$SDKROOT -target $${arch%%-simulator}-apple-ios15.0-simulator"; \
			export LDFLAGS="-arch $${arch%%-simulator} -L$$SDKROOT/usr/lib/"; \
			export INSTALL_DIR=$(JPEG_INSTALL_DIR)/simulator; \
		else \
			export SDKROOT=$(SDK_IPHONEOS_PATH); \
			export HOST=aarch64-apple-darwin; \
			export CFLAGS="$(COMMON_FLAGS) -arch $$arch -isysroot $$SDKROOT -target $$arch-apple-ios15.0"; \
			export LDFLAGS="-arch $$arch -L$$SDKROOT/usr/lib/"; \
			export INSTALL_DIR=$(JPEG_INSTALL_DIR)/ios; \
		fi; \
		export CPPFLAGS="$$CFLAGS"; \
		export CXXFLAGS="$$CFLAGS"; \
		echo "Configuring jpeg for $$arch"; \
		$(JPEG_SRC)/configure --host=$$HOST --prefix=$$INSTALL_DIR \
			--enable-static --disable-shared \
			--with-pic || exit 1; \
		echo "Building jpeg for $$arch"; \
		$(MAKE) V=1 -j8 && $(MAKE) install || exit 1; \
	done
	@echo "Creating jpeg simulator universal binary"
	mkdir -p $(JPEG_INSTALL_DIR)/simulator/lib
	xcrun lipo -create \
		$(JPEG_BUILD_DIR)/arm64-simulator/.libs/libjpeg.a \
		$(JPEG_BUILD_DIR)/x86_64-simulator/.libs/libjpeg.a \
		-output $(JPEG_INSTALL_DIR)/simulator/lib/libjpeg.a

$(JPEG_SRC)/configure:
	curl http://www.ijg.org/files/$(JPEG_SRC_NAME).tar.gz | tar -xpf-

# Leptonica target
leptonica: clean-leptonica
	@echo "Building Leptonica for architectures: $(ARCHS)"
	for arch in $(ARCHS); do \
		echo "Building Leptonica for $$arch"; \
		mkdir -p $(LEPT_BUILD_DIR)/$$arch; \
		cd $(LEPT_BUILD_DIR)/$$arch; \
		$(COMMON_EXPORTS); \
		if [ $$arch = "arm64-simulator" ] || [ $$arch = "x86_64-simulator" ]; then \
			$(SIMULATOR_FLAGS); \
			export INSTALL_DIR=$(LEPT_INSTALL_DIR)/simulator; \
		else \
			$(DEVICE_FLAGS); \
			export INSTALL_DIR=$(LEPT_INSTALL_DIR)/ios; \
		fi; \
		export CPPFLAGS="$$CFLAGS"; \
		export CXXFLAGS="$$CFLAGS"; \
		echo "Configuring Leptonica for $$arch"; \
		$(LEPTON_SRC)/configure --host=$$HOST --prefix=$$INSTALL_DIR \
			--enable-static --disable-shared --disable-programs \
			--without-zlib --without-jpeg --without-libpng --without-giflib \
			--without-libtiff --without-libwebp --without-libopenjpeg \
			--without-webp --without-webpmux --with-pic \
			ac_cv_prog_have_pkg_config=no PKG_CONFIG=/bin/false || exit 1; \
		echo "Building Leptonica for $$arch"; \
		$(MAKE) V=1 -j8 && $(MAKE) install || exit 1; \
	done
	@echo "Creating Leptonica simulator universal binary"
	mkdir -p $(LEPT_INSTALL_DIR)/simulator/lib
	xcrun lipo -create \
		$(LEPT_BUILD_DIR)/arm64-simulator/src/.libs/libleptonica.a \
		$(LEPT_BUILD_DIR)/x86_64-simulator/src/.libs/libleptonica.a \
		-output $(LEPT_INSTALL_DIR)/simulator/lib/libleptonica.a

# Tesseract targets
autogen-tesseract:
	cd $(TESSERACT_SRC) && \
	if [ ! -f configure ]; then \
		./autogen.sh; \
	fi

tesseract: clean-tesseract autogen-tesseract
	@echo "Building Tesseract for architectures: $(ARCHS)"
	for arch in $(ARCHS); do \
		echo "Building Tesseract for $$arch"; \
		mkdir -p $(TESS_BUILD_DIR)/$$arch; \
		cd $(TESS_BUILD_DIR)/$$arch; \
		$(COMMON_EXPORTS); \
		if [ $$arch = "arm64-simulator" ] || [ $$arch = "x86_64-simulator" ]; then \
			$(SIMULATOR_FLAGS); \
			export INSTALL_DIR=$(TESS_BUILD_DIR)/$$arch; \
			export LEPTONICA_LIBS="-L$(LEPT_INSTALL_DIR)/simulator/lib -lleptonica"; \
			export LEPTONICA_CFLAGS="-I$(LEPT_INSTALL_DIR)/simulator/include/leptonica"; \
		else \
			$(DEVICE_FLAGS); \
			export INSTALL_DIR=$(TESS_BUILD_DIR)/$$arch; \
			export LEPTONICA_LIBS="-L$(LEPT_INSTALL_DIR)/ios/lib -lleptonica"; \
			export LEPTONICA_CFLAGS="-I$(LEPT_INSTALL_DIR)/ios/include/leptonica"; \
		fi; \
		export CPPFLAGS="$$CFLAGS $$LEPTONICA_CFLAGS"; \
		export CXXFLAGS="$$CFLAGS $$LEPTONICA_CFLAGS"; \
		cd $(TESSERACT_SRC) && $(MAKE) distclean; \
		cd $(TESS_BUILD_DIR)/$$arch; \
		echo "Configuring Tesseract for $$arch"; \
		$(TESSERACT_SRC)/configure --host=$$HOST --prefix=$$INSTALL_DIR \
			--disable-shared --disable-graphics --disable-legacy --disable-doc \
			--disable-openmp --without-curl --without-archive --without-tensorflow \
			--without-webp --without-png --without-zlib --without-giflib \
			--without-tiff --without-libtiff --without-zstd --without-webp \
			--with-pic LEPTONICA_LIBS="$$LEPTONICA_LIBS" \
			LEPTONICA_CFLAGS="$$LEPTONICA_CFLAGS" \
			ac_cv_prog_have_pkg_config=no PKG_CONFIG=/bin/false || exit 1; \
		echo "Building Tesseract for $$arch"; \
		$(MAKE) V=1 -j8 && $(MAKE) install || exit 1; \
	done
	@echo "Creating Tesseract simulator universal binary"
	mkdir -p $(TESS_INSTALL_DIR)/simulator/lib $(TESS_INSTALL_DIR)/ios/lib
	mkdir -p $(TESS_INSTALL_DIR)/ios/include/tesseract $(TESS_INSTALL_DIR)/simulator/include/tesseract
	if [ -f $(TESS_BUILD_DIR)/arm64-simulator/lib/libtesseract.a ] && [ -f $(TESS_BUILD_DIR)/x86_64-simulator/lib/libtesseract.a ]; then \
		xcrun lipo -create \
			$(TESS_BUILD_DIR)/arm64-simulator/lib/libtesseract.a \
			$(TESS_BUILD_DIR)/x86_64-simulator/lib/libtesseract.a \
			-output $(TESS_INSTALL_DIR)/simulator/lib/libtesseract.a; \
	else \
		echo "Error: Simulator architectures not built correctly"; \
		echo "arm64-simulator: $$(ls -l $(TESS_BUILD_DIR)/arm64-simulator/lib 2>/dev/null)"; \
		echo "x86_64-simulator: $$(ls -l $(TESS_BUILD_DIR)/x86_64-simulator/lib 2>/dev/null)"; \
		exit 1; \
	fi
	cp $(TESS_BUILD_DIR)/arm64/lib/libtesseract.a $(TESS_INSTALL_DIR)/ios/lib/
	cp -R $(TESS_BUILD_DIR)/arm64/include/tesseract/* $(TESS_INSTALL_DIR)/ios/include/tesseract/
	cp -R $(TESS_BUILD_DIR)/x86_64-simulator/include/tesseract/* $(TESS_INSTALL_DIR)/simulator/include/tesseract/

# XCFramework creation
xcframeworks: jpeg-xcframework leptonica-xcframework tesseract-xcframework

define create_xcframework
	mkdir -p $(FRAMEWORK_DIR)
	rm -Rf $(FRAMEWORK_DIR)/$(1).xcframework
	xcodebuild -create-xcframework \
		-library $(2)/ios/lib/lib$(3).a \
		-headers $(2)/ios/include \
		-library $(2)/simulator/lib/lib$(3).a \
		-headers $(2)/simulator/include \
		-output $(FRAMEWORK_DIR)/$(1).xcframework
endef

jpeg-xcframework:
	$(call create_xcframework,JPEG,$(JPEG_INSTALL_DIR),jpeg)

leptonica-xcframework:
	$(call create_xcframework,Leptonica,$(LEPT_INSTALL_DIR),leptonica)

tesseract-xcframework:
	$(call create_xcframework,Tesseract,$(TESS_INSTALL_DIR),tesseract)

# Clean targets
clean-jpeg:
	rm -Rf $(JPEG_BUILD_DIR)
	rm -Rf $(JPEG_INSTALL_DIR)
	rm -Rf $(JPEG_SRC)

clean-leptonica:
	rm -Rf $(LEPT_BUILD_DIR)
	rm -Rf $(LEPT_INSTALL_DIR)

clean-tesseract:
	rm -Rf $(TESS_BUILD_DIR)
	rm -Rf $(TESS_INSTALL_DIR)

clean: clean-jpeg clean-leptonica clean-tesseract
	cd $(TESSERACT_SRC) && [ -f Makefile ] && $(MAKE) distclean || true
	rm -Rf $(BUILD_DIR) $(INSTALL_DIR)
