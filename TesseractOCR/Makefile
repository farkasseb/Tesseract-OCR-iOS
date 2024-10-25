# Root paths
TESSERACT_ROOT = $(shell pwd)
BUILD_DIR = $(TESSERACT_ROOT)/build
INSTALL_DIR = $(TESSERACT_ROOT)/install
FRAMEWORK_DIR = $(TESSERACT_ROOT)/xcframework

# SDK paths
SDK_IPHONEOS_PATH=$(shell xcrun --sdk iphoneos --show-sdk-path)
SDK_IPHONESIMULATOR_PATH=$(shell xcrun --sdk iphonesimulator --show-sdk-path)

# Architectures
ARCHS = arm64 arm64-simulator x86_64-simulator

# Common build configuration
COMMON_FLAGS = -pipe -no-cpp-precomp -miphoneos-version-min=15.0 -O2

# Library configurations
JPEG_SRC_NAME = jpegsrc.v9a
JPEG_DIR_NAME = jpeg-9a
JPEG_SRC = $(TESSERACT_ROOT)/$(JPEG_DIR_NAME)
JPEG_BUILD_DIR = $(BUILD_DIR)/jpeg
JPEG_INSTALL_DIR = $(INSTALL_DIR)/jpeg

PNG_NAME = libpng-1.6.44
PNG_SRC = $(TESSERACT_ROOT)/$(PNG_NAME)
PNG_BUILD_DIR = $(BUILD_DIR)/png
PNG_INSTALL_DIR = $(INSTALL_DIR)/png

TIFF_NAME = tiff-4.7.0
TIFF_SRC = $(TESSERACT_ROOT)/$(TIFF_NAME)
TIFF_BUILD_DIR = $(BUILD_DIR)/tiff
TIFF_INSTALL_DIR = $(INSTALL_DIR)/tiff

LEPTON_NAME = leptonica
LEPTON_SRC = $(TESSERACT_ROOT)/$(LEPTON_NAME)
LEPT_BUILD_DIR = $(BUILD_DIR)/leptonica
LEPT_INSTALL_DIR = $(INSTALL_DIR)/leptonica

TESSERACT_NAME = tesseract-ocr
TESSERACT_SRC = $(TESSERACT_ROOT)/$(TESSERACT_NAME)
TESS_BUILD_DIR = $(BUILD_DIR)/tesseract
TESS_INSTALL_DIR = $(INSTALL_DIR)/tesseract

# Function to determine platform directory
define get_platform_dir
case "$(1)" in \
  *simulator) \
    echo "simulator";; \
  *) \
    echo "ios";; \
esac
endef

# Common exports for all builds
define COMMON_EXPORTS
	export CC="clang"; \
	export CXX="clang++"; \
	export PKG_CONFIG_PATH=""; \
	export PKG_CONFIG_LIBDIR=""; \
	platform_dir=`$(call get_platform_dir,$$arch)`; \
	export PNG_LIBS="-L$(PNG_INSTALL_DIR)/$$platform_dir/lib -lpng"; \
	export PNG_CFLAGS="-I$(PNG_INSTALL_DIR)/$$platform_dir/include"; \
	export JPEG_LIBS="-L$(JPEG_INSTALL_DIR)/$$platform_dir/lib -ljpeg"; \
	export JPEG_CFLAGS="-I$(JPEG_INSTALL_DIR)/$$platform_dir/include"; \
	export TIFF_LIBS="-L$(TIFF_INSTALL_DIR)/$$platform_dir/lib -ltiff"; \
	export TIFF_CFLAGS="-I$(TIFF_INSTALL_DIR)/$$platform_dir/include"; \
	export LEPTONICA_LIBS="-L$(LEPT_INSTALL_DIR)/$$platform_dir/lib -lleptonica"; \
	export LEPTONICA_CFLAGS="-I$(LEPT_INSTALL_DIR)/$$platform_dir/include/leptonica"
endef

# Build flag definitions
define SIMULATOR_FLAGS
	export SDKROOT=$(SDK_IPHONESIMULATOR_PATH); \
	export HOST=$${arch%%-simulator}-apple-darwin; \
	export CFLAGS="$(COMMON_FLAGS) -arch $${arch%%-simulator} -isysroot $$SDKROOT -target $${arch%%-simulator}-apple-ios15.0-simulator"; \
	export LDFLAGS="-arch $${arch%%-simulator} -L$$SDKROOT/usr/lib/"
endef

define DEVICE_FLAGS
	export SDKROOT=$(SDK_IPHONEOS_PATH); \
	export HOST=$$arch-apple-darwin; \
	export CFLAGS="$(COMMON_FLAGS) -arch $$arch -isysroot $$SDKROOT -target $$arch-apple-ios15.0"; \
	export LDFLAGS="-arch $$arch -L$$SDKROOT/usr/lib/"
endef

# Targets
.PHONY: all build frameworks jpeg png tiff leptonica tesseract autogen-tesseract xcframeworks jpeg-xcframework png-xcframework tiff-xcframework leptonica-xcframework tesseract-xcframework clean clean-jpeg clean-png clean-tiff clean-leptonica clean-tesseract distclean-tesseract clean-frameworks clean-all

all: build frameworks

build: jpeg png tiff leptonica tesseract

frameworks: xcframeworks

# JPEG target
jpeg: clean-jpeg $(JPEG_SRC)/configure
	@echo "Building jpeg for architectures: $(ARCHS)"
	@for arch in $(ARCHS); do \
		echo "Building jpeg for $$arch"; \
		mkdir -p $(JPEG_BUILD_DIR)/$$arch; \
		cd $(JPEG_BUILD_DIR)/$$arch; \
		$(COMMON_EXPORTS); \
		if [[ "$$arch" == *simulator* ]]; then \
			$(SIMULATOR_FLAGS); \
			export INSTALL_DIR=$(JPEG_INSTALL_DIR)/simulator; \
		else \
			$(DEVICE_FLAGS); \
			export INSTALL_DIR=$(JPEG_INSTALL_DIR)/ios; \
		fi; \
		export CPPFLAGS="$$CFLAGS"; \
		export CXXFLAGS="$$CFLAGS"; \
		echo "Configuring jpeg for $$arch with host $${HOST/arm64/aarch64}"; \
		$(JPEG_SRC)/configure \
			--host="$${HOST/arm64/aarch64}" \
			--prefix="$$INSTALL_DIR" \
			--enable-static \
			--disable-shared \
			--with-pic || exit 1; \
		echo "Building jpeg for $$arch"; \
		$(MAKE) -j8 && $(MAKE) install || exit 1; \
	done
	@echo "Creating jpeg simulator universal binary"
	@mkdir -p $(JPEG_INSTALL_DIR)/simulator/lib
	@xcrun lipo -create \
		$(JPEG_BUILD_DIR)/arm64-simulator/.libs/libjpeg.a \
		$(JPEG_BUILD_DIR)/x86_64-simulator/.libs/libjpeg.a \
		-output $(JPEG_INSTALL_DIR)/simulator/lib/libjpeg.a
	@echo "Successfully built jpeg!"

$(JPEG_SRC)/configure:
	curl http://www.ijg.org/files/$(JPEG_SRC_NAME).tar.gz | tar -xpf-

# PNG target
png: clean-png $(PNG_SRC)/configure
	@echo "Building png for architectures: $(ARCHS)"
	@for arch in $(ARCHS); do \
		echo "Building png for $$arch"; \
		mkdir -p $(PNG_BUILD_DIR)/$$arch; \
		cd $(PNG_BUILD_DIR)/$$arch; \
		$(COMMON_EXPORTS); \
		if [[ "$$arch" == *simulator* ]]; then \
			$(SIMULATOR_FLAGS); \
			export INSTALL_DIR=$(PNG_INSTALL_DIR)/simulator; \
		else \
			$(DEVICE_FLAGS); \
			export INSTALL_DIR=$(PNG_INSTALL_DIR)/ios; \
		fi; \
		export CPPFLAGS="$$CFLAGS"; \
		export CXXFLAGS="$$CFLAGS"; \
		echo "Configuring png for $$arch with host $$HOST"; \
		$(PNG_SRC)/configure \
			--host="$$HOST" \
			--prefix="$$INSTALL_DIR" \
			--enable-static \
			--disable-shared \
			--with-pic || exit 1; \
		echo "Building png for $$arch"; \
		$(MAKE) -j8 && $(MAKE) install || exit 1; \
	done
	@echo "Creating png simulator universal binary"
	@mkdir -p $(PNG_INSTALL_DIR)/simulator/lib
	@xcrun lipo -create \
		$(PNG_BUILD_DIR)/arm64-simulator/.libs/libpng16.a \
		$(PNG_BUILD_DIR)/x86_64-simulator/.libs/libpng16.a \
		-output $(PNG_INSTALL_DIR)/simulator/lib/libpng16.a
	@echo "Successfully built png!"

$(PNG_SRC)/configure:
	curl -L https://download.sourceforge.net/libpng/$(PNG_NAME).tar.gz | tar -xpf-

# TIFF target
tiff: clean-tiff jpeg $(TIFF_SRC)/configure
	@echo "Building tiff for architectures: $(ARCHS)"
	@for arch in $(ARCHS); do \
		echo "Building tiff for $$arch"; \
		mkdir -p $(TIFF_BUILD_DIR)/$$arch; \
		cd $(TIFF_BUILD_DIR)/$$arch; \
		platform_dir=`$(call get_platform_dir,$$arch)`; \
		$(COMMON_EXPORTS); \
		if [[ "$$arch" == *simulator* ]]; then \
			$(SIMULATOR_FLAGS); \
			export INSTALL_DIR=$(TIFF_INSTALL_DIR)/simulator; \
		else \
			$(DEVICE_FLAGS); \
			export INSTALL_DIR=$(TIFF_INSTALL_DIR)/ios; \
		fi; \
		export CPPFLAGS="$$CFLAGS $$JPEG_CFLAGS"; \
		export CXXFLAGS="$$CFLAGS $$JPEG_CFLAGS"; \
		export LDFLAGS="$$LDFLAGS $$JPEG_LIBS -lz"; \
		echo "Configuring tiff for $$arch with host $$HOST"; \
		$(TIFF_SRC)/configure \
			--host="$$HOST" \
			--prefix="$$INSTALL_DIR" \
			--enable-static \
			--disable-shared \
			--enable-fast-install \
			--disable-tools \
			--disable-tests \
			--without-x \
			--with-jpeg-include-dir="$(JPEG_INSTALL_DIR)/$$platform_dir/include" \
			--with-jpeg-lib-dir="$(JPEG_INSTALL_DIR)/$$platform_dir/lib" \
			--with-pic || exit 1; \
		echo "Building tiff for $$arch"; \
		$(MAKE) -j8 && $(MAKE) install || exit 1; \
	done
	@echo "Creating tiff simulator universal binary"
	@mkdir -p $(TIFF_INSTALL_DIR)/simulator/lib
	@xcrun lipo -create \
		$(TIFF_BUILD_DIR)/arm64-simulator/libtiff/.libs/libtiff.a \
		$(TIFF_BUILD_DIR)/x86_64-simulator/libtiff/.libs/libtiff.a \
		-output $(TIFF_INSTALL_DIR)/simulator/lib/libtiff.a
	@echo "Successfully built tiff!"

$(TIFF_SRC)/configure:
	curl -L https://download.osgeo.org/libtiff/$(TIFF_NAME).tar.gz | tar -xpf-

# Leptonica target
leptonica: clean-leptonica jpeg png tiff
	@echo "Building Leptonica for architectures: $(ARCHS)"
	@for arch in $(ARCHS); do \
		echo "Building Leptonica for $$arch"; \
		mkdir -p $(LEPT_BUILD_DIR)/$$arch; \
		cd $(LEPT_BUILD_DIR)/$$arch; \
		$(COMMON_EXPORTS); \
		if [[ "$$arch" == *simulator* ]]; then \
			$(SIMULATOR_FLAGS); \
			export INSTALL_DIR=$(LEPT_INSTALL_DIR)/simulator; \
		else \
			$(DEVICE_FLAGS); \
			export INSTALL_DIR=$(LEPT_INSTALL_DIR)/ios; \
		fi; \
		export CPPFLAGS="$$CFLAGS $$PNG_CFLAGS $$JPEG_CFLAGS $$TIFF_CFLAGS"; \
		export CXXFLAGS="$$CFLAGS $$PNG_CFLAGS $$JPEG_CFLAGS $$TIFF_CFLAGS"; \
		export LDFLAGS="$$LDFLAGS $$PNG_LIBS $$JPEG_LIBS $$TIFF_LIBS -lz"; \
		echo "Configuring Leptonica for $$arch with host $$HOST"; \
		$(LEPTON_SRC)/configure \
			--host="$$HOST" \
			--prefix="$$INSTALL_DIR" \
			--enable-static \
			--disable-shared \
			--disable-programs \
			--with-zlib \
			--with-jpeg \
			--with-libpng \
			--with-libtiff \
			--with-pic || exit 1; \
		echo "Building Leptonica for $$arch"; \
		$(MAKE) -j8 && $(MAKE) install || exit 1; \
	done
	@echo "Creating Leptonica simulator universal binary"
	@mkdir -p $(LEPT_INSTALL_DIR)/simulator/lib
	@xcrun lipo -create \
		$(LEPT_BUILD_DIR)/arm64-simulator/src/.libs/libleptonica.a \
		$(LEPT_BUILD_DIR)/x86_64-simulator/src/.libs/libleptonica.a \
		-output $(LEPT_INSTALL_DIR)/simulator/lib/libleptonica.a
	@echo "Successfully built Leptonica!"

# Tesseract targets
autogen-tesseract:
	@cd $(TESSERACT_SRC) && \
	if [ ! -f configure ]; then \
		./autogen.sh; \
	fi

tesseract: clean-tesseract autogen-tesseract leptonica
	@echo "Building Tesseract for architectures: $(ARCHS)"
	@for arch in $(ARCHS); do \
		echo "Building Tesseract for $$arch"; \
		mkdir -p $(TESS_BUILD_DIR)/$$arch; \
		cd $(TESS_BUILD_DIR)/$$arch; \
		$(COMMON_EXPORTS); \
		if [[ "$$arch" == *simulator* ]]; then \
			$(SIMULATOR_FLAGS); \
			export INSTALL_DIR=$(TESS_BUILD_DIR)/$$arch; \
		else \
			$(DEVICE_FLAGS); \
			export INSTALL_DIR=$(TESS_BUILD_DIR)/$$arch; \
		fi; \
		export LIBS="$$PNG_LIBS $$JPEG_LIBS $$TIFF_LIBS -lz"; \
		export CPPFLAGS="$$CFLAGS $$LEPTONICA_CFLAGS $$PNG_CFLAGS $$JPEG_CFLAGS $$TIFF_CFLAGS"; \
		export CXXFLAGS="$$CFLAGS $$LEPTONICA_CFLAGS $$PNG_CFLAGS $$JPEG_CFLAGS $$TIFF_CFLAGS"; \
		export LDFLAGS="$$LDFLAGS $$LEPTONICA_LIBS $$PNG_LIBS $$JPEG_LIBS $$TIFF_LIBS -lz"; \
		cd $(TESSERACT_SRC) && $(MAKE) distclean; \
		cd $(TESS_BUILD_DIR)/$$arch; \
		echo "Configuring Tesseract for $$arch with host $$HOST"; \
		$(TESSERACT_SRC)/configure \
			--host="$$HOST" \
			--prefix="$$INSTALL_DIR" \
			--disable-shared \
			--disable-graphics \
			--disable-legacy \
			--disable-doc \
			--disable-openmp \
			--with-pic \
			LEPTONICA_LIBS="$$LEPTONICA_LIBS" \
			LEPTONICA_CFLAGS="$$LEPTONICA_CFLAGS" || exit 1; \
		echo "Building Tesseract for $$arch"; \
		$(MAKE) -j8 && $(MAKE) install || exit 1; \
	done
	@echo "Creating Tesseract simulator universal binary"
	@mkdir -p $(TESS_INSTALL_DIR)/simulator/lib $(TESS_INSTALL_DIR)/ios/lib
	@mkdir -p $(TESS_INSTALL_DIR)/ios/include $(TESS_INSTALL_DIR)/simulator/include
	@xcrun lipo -create \
		$(TESS_BUILD_DIR)/arm64-simulator/lib/libtesseract.a \
		$(TESS_BUILD_DIR)/x86_64-simulator/lib/libtesseract.a \
		-output $(TESS_INSTALL_DIR)/simulator/lib/libtesseract.a
	@cp $(TESS_BUILD_DIR)/arm64/lib/libtesseract.a $(TESS_INSTALL_DIR)/ios/lib/
	@cp -R $(TESS_BUILD_DIR)/arm64/include/* $(TESS_INSTALL_DIR)/ios/include/
	@cp -R $(TESS_BUILD_DIR)/x86_64-simulator/include/* $(TESS_INSTALL_DIR)/simulator/include/
	@echo "Successfully built Tesseract!"

# XCFramework creation
xcframeworks: jpeg-xcframework png-xcframework tiff-xcframework leptonica-xcframework tesseract-xcframework

define create_xcframework
	@mkdir -p $(FRAMEWORK_DIR)
	@rm -rf $(FRAMEWORK_DIR)/$(1).xcframework
	@xcodebuild -create-xcframework \
		-library $(2)/ios/lib/lib$(3).a \
		-headers $(2)/ios/include \
		-library $(2)/simulator/lib/lib$(3).a \
		-headers $(2)/simulator/include \
		-output $(FRAMEWORK_DIR)/$(1).xcframework
	@echo "Successfully created $(1).xcframework!"
endef

jpeg-xcframework:
	$(call create_xcframework,JPEG,$(JPEG_INSTALL_DIR),jpeg)

png-xcframework:
	$(call create_xcframework,PNG,$(PNG_INSTALL_DIR),png16)

tiff-xcframework:
	$(call create_xcframework,TIFF,$(TIFF_INSTALL_DIR),tiff)

leptonica-xcframework:
	$(call create_xcframework,Leptonica,$(LEPT_INSTALL_DIR),leptonica)

tesseract-xcframework:
	$(call create_xcframework,Tesseract,$(TESS_INSTALL_DIR),tesseract)

# Clean targets
clean-jpeg:
	@rm -rf $(JPEG_BUILD_DIR)
	@rm -rf $(JPEG_INSTALL_DIR)
	@rm -rf $(JPEG_SRC)

clean-png:
	@rm -rf $(PNG_BUILD_DIR)
	@rm -rf $(PNG_INSTALL_DIR)
	@rm -rf $(PNG_SRC)

clean-tiff:
	@rm -rf $(TIFF_BUILD_DIR)
	@rm -rf $(TIFF_INSTALL_DIR)
	@rm -rf $(TIFF_SRC)

clean-leptonica:
	@rm -rf $(LEPT_BUILD_DIR)
	@rm -rf $(LEPT_INSTALL_DIR)

clean-tesseract:
	@rm -rf $(TESS_BUILD_DIR)
	@rm -rf $(TESS_INSTALL_DIR)

clean-frameworks:
	@rm -rf $(FRAMEWORK_DIR)

clean: clean-jpeg clean-png clean-tiff clean-leptonica clean-tesseract
	@cd $(TESSERACT_SRC) && [ -f Makefile ] && $(MAKE) distclean || true
	@rm -rf $(BUILD_DIR) $(INSTALL_DIR)

clean-all: clean clean-frameworks
