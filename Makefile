SHELL := /bin/bash
.SHELLFLAGS = -ec

# Prerequisite variables
SOURCEDIR   := $(shell printf "%q\n" "$(shell pwd)")
OUTPUTDIR   := $(SOURCEDIR)/artifacts
WORKINGDIR  := $(SOURCEDIR)/Natives/build
DETECTPLAT  := $(shell uname -s)
DETECTARCH  := $(shell uname -m)
VERSION     := 2.2 # Need to look into automatic changing later
BRANCH      := $(shell git branch --show-current)
COMMIT      := $(shell git log --oneline | sed '2,10000000d' | cut -b 1-7)

# Release vs Debug
RELEASE ?= 0

# Check if running on github runner
RUNNER ?= 0

ifeq (1,$(RELEASE))
CMAKE_BUILD_TYPE := Release
else
CMAKE_BUILD_TYPE := Debug
endif


# Distinguish iOS from macOS, and *OS from others
ifeq ($(DETECTPLAT),Darwin)
ifeq ($(shell sw_vers -productName),macOS)
IOS         := 0
SDKPATH     ?= $(shell xcrun --sdk iphoneos --show-sdk-path)
BOOTJDK     ?= $(shell /usr/libexec/java_home -v 1.8)/bin
$(warning Building on macOS.)
else
IOS         := 1
SDKPATH     ?= /usr/share/SDKs/iPhoneOS.sdk
BOOTJDK     ?= /usr/lib/jvm/java-8-openjdk/bin
$(warning Building on iOS.)
endif
else ifeq ($(DETECTPLAT),Linux)
IOS         := 0
# SDKPATH presence is checked later
BOOTJDK     ?= /usr/bin
$(warning Building on Linux. Note that all targets may not compile or require external components.)
else
$(error This platform is not currently supported for building PojavLauncher.)
endif

# IPABuilder depending variables
POJAV_BUNDLE_DIR    ?= $(OUTPUTDIR)/PojavLauncher.app
POJAV_JRE8_DIR       ?= $(SOURCEDIR)/depends/java-8-openjdk
POJAV_JRE17_DIR       ?= $(SOURCEDIR)/depends/java-17-openjdk

# Function to use later for checking dependencies
DEPCHECK   = $(shell $(1) >/dev/null 2>&1 && echo 1)

# Function to modify Info.plist files
INFOPLIST  =  \
	if [ '$(4)' = '0' ]; then \
		plutil -replace $(1) -string $(2) $(3); \
	else \
		plutil -value $(2) -key $(1) $(3); \
	fi

# Function to check directories
DIRCHECK   = \
	if [ ! -d '$(1)' ]; then \
		mkdir $(1); \
	else \
		sudo rm -rf $(1)/*; \
	fi

# Make sure everything is already available for use. Error if they require something
ifneq ($(call DEPCHECK,cmake --version),1)
$(error You need to install cmake)
endif

ifneq ($(call DEPCHECK,$(BOOTJDK)/javac -version),1)
$(error You need to install JDK 8)
endif

ifeq ($(IOS),0)
ifeq ($(filter 1.8.0,$(shell $(BOOTJDK)/javac -version &> javaver.txt && cat javaver.txt | cut -b 7-11 && rm -rf javaver.txt)),)
$(error You need to install JDK 8)
endif
endif

ifneq ($(call DEPCHECK,ldid),1)
$(error You need to install ldid)
endif

ifeq ($(DETECTPLAT),Linux)
ifneq ($(call DEPCHECK,lld),1)
$(error You need to install lld)
endif
endif

ifneq ($(call DEPCHECK,nproc --version),1)
ifneq ($(call DEPCHECK,gnproc --version),1)
$(warning Unable to determine number of threads, defaulting to 2.)
JOBS   ?= 2
else
JOBS   ?= $(shell gnproc)
endif
else
JOBS   ?= $(shell nproc)
endif

ifndef SDKPATH
$(error You need to specify SDKPATH to the path of iPhoneOS.sdk. The SDK version should be 14.0 or newer.)
endif

# Now for the actual Makefile recipes.
#  all     - runs clean, native, java, extras, and package.
#  check   - Makes sure that all variables are correct.
#  native  - Builds the Objective-C code.
#  java    - Builds the Java code.
#  jre     - Download iOS JRE and/or unpack it for use.
#  extras  - Builds the Assets and Storyboard.
#  package - Builds the application package.
#  deploy  - runs native and java + installs to jailbroken device.
#  dsym    - Generates debug symbol files

all: clean native java jre extras package dsym

check:
	@printf '\nDumping all Makefile variables.\n'
	@printf 'DETECTPLAT           - $(DETECTPLAT)\n'
	@printf 'DETECTARCH           - $(DETECTARCH)\n'
	@printf 'SDKPATH              - $(SDKPATH)\n'
	@printf 'BOOTJDK              - $(BOOTJDK)\n'
	@printf 'SOURCEDIR            - $(SOURCEDIR)\n'
	@printf 'WORKINGDIR           - $(WORKINGDIR)\n'
	@printf 'OUTPUTDIR            - $(OUTPUTDIR)\n'
	@printf 'JOBS                 - $(JOBS)\n'
	@printf 'VERSION              - $(VERSION)\n'
	@printf 'BRANCH               - $(BRANCH)\n'
	@printf 'COMMIT               - $(COMMIT)\n'
	@printf 'RELEASE              - $(RELEASE)\n'
	@printf 'IOS                  - $(IOS)\n'
	@printf 'POJAV_BUNDLE_DIR     - $(POJAV_BUNDLE_DIR)\n'
	@printf 'POJAV_JRE_DIR        - $(POJAV_JRE_DIR)\n'
	@printf '\nVerify that all of the variables are correct.\n'
	
native:
	@echo '[PojavLauncher v$(VERSION)] native - start'
	@mkdir -p $(WORKINGDIR)
	@cd $(WORKINGDIR) && cmake . \
		-DCMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE) \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_SYSTEM_PROCESSOR=aarch64 \
		-DCMAKE_OSX_SYSROOT="$(SDKPATH)" \
		-DCMAKE_OSX_ARCHITECTURES=arm64 \
		-DCMAKE_C_FLAGS="-arch arm64 -miphoneos-version-min=12.2" \
		-DCONFIG_BRANCH="$(BRANCH)" \
		-DCONFIG_COMMIT="$(COMMIT)" \
		-DCONFIG_RELEASE=$(RELEASE) \
		..

	@cmake --build $(WORKINGDIR) --config $(CMAKE_BUILD_TYPE) -j$(JOBS)
	@# --target awt_headless awt_xawt libOSMesaOverride.dylib tinygl4angle PojavLauncher
	@rm $(WORKINGDIR)/libawt_headless.dylib
	@echo '[PojavLauncher v$(VERSION)] native - end'

java:
	@echo '[PojavLauncher v$(VERSION)] java - start'
	@cd $(SOURCEDIR)/JavaApp; \
	mkdir -p local_out/classes; \
	$(BOOTJDK)/javac -cp "libs/*:libs_caciocavallo/*" -d local_out/classes $$(find src -type f -name "*.java" -print) -XDignore.symbol.file || exit 1; \
	cd local_out/classes; \
	$(BOOTJDK)/jar -cf ../launcher.jar android com net || exit 1; \
	cp $(SOURCEDIR)/JavaApp/libs/lwjgl3-minecraft.jar ../lwjgl3-minecraft.jar || exit 1; \
	$(BOOTJDK)/jar -uf ../lwjgl3-minecraft.jar org || exit 1;
	@echo '[PojavLauncher v$(VERSION)] java - end'

jre:
	@echo '[PojavLauncher v$(VERSION)] jre - start'
	@mkdir -p $(SOURCEDIR)/depends; \
	cd $(SOURCEDIR)/depends; \
	if [ ! -f "java-8-openjdk/release" ] && [ ! -f "$(ls jre8-*.tar.xz)" ]; then \
		if [ "$(RUNNER)" != "1" ]; then \
			wget 'https://github.com/PojavLauncherTeam/android-openjdk-build-multiarch/releases/download/jre8-40df388/jre8-arm64-20220811-release.tar.xz' -q --show-progress; \
		fi; \
		mkdir java-8-openjdk && cd java-8-openjdk; \
		tar xvf ../jre8-*.tar.xz; \
		rm ../jre8-*.tar.xz; \
	fi; \
	cd $(SOURCEDIR)/depends; \
	if [ ! -f "java-17-openjdk/release" ] && [ ! -f "$(ls jre17-*.tar.xz)" ]; then \
		if [ "$(RUNNER)" != "1" ]; then \
			wget 'https://github.com/PojavLauncherTeam/android-openjdk-build-multiarch/releases/download/jre17-ca01427/jre17-arm64-20220817-release.tar.xz' -q --show-progress; \
		fi; \
		mkdir java-17-openjdk && cd java-17-openjdk; \
		tar xvf ../jre17-*.tar.xz; \
		rm ../jre17-*.tar.xz; \
	fi; \
	cd ..; \
	rm -rf $(SOURCEDIR)/depends/java-*-openjdk/{bin,include,jre,lib/{ct.sym,libjsig.dylib,src.zip,tools.jar}}; \
	$(call DIRCHECK,$(WORKINGDIR)/PojavLauncher.app/jvm); \
	cp -R $(POJAV_JRE8_DIR) $(WORKINGDIR)/PojavLauncher.app/jvm/; \
	cp -R $(POJAV_JRE17_DIR) $(WORKINGDIR)/PojavLauncher.app/jvm/; \
	cp $(WORKINGDIR)/libawt_xawt.dylib $(WORKINGDIR)/PojavLauncher.app/jvm/java-17-openjdk/lib/; \
	cp $(WORKINGDIR)/libawt_xawt.dylib $(WORKINGDIR)/PojavLauncher.app/jvm/java-8-openjdk/lib/; \
	echo '[PojavLauncher v$(VERSION)] jre - end'

package: native java jre
	@echo '[PojavLauncher v$(VERSION)] package - start'
	$(call DIRCHECK,$(WORKINGDIR)/PojavLauncher.app/libs)
	$(call DIRCHECK,$(WORKINGDIR)/PojavLauncher.app/libs_caciocavallo)
	$(call DIRCHECK,$(WORKINGDIR)/PojavLauncher.app/libs_caciocavallo17)
	@cp -R $(SOURCEDIR)/Natives/resources/* $(WORKINGDIR)/PojavLauncher.app/ || exit 1
	@cp $(WORKINGDIR)/*.dylib $(WORKINGDIR)/PojavLauncher.app/Frameworks/ || exit 1
	@cp -R $(WORKINGDIR)/*.framework $(WORKINGDIR)/PojavLauncher.app/Frameworks/ || exit 1
	@cp -R $(SOURCEDIR)/JavaApp/libs/* $(WORKINGDIR)/PojavLauncher.app/libs/ || exit 1
	@cp $(SOURCEDIR)/JavaApp/local_out/*.jar $(WORKINGDIR)/PojavLauncher.app/libs/ || exit 1
	@cp -R $(SOURCEDIR)/JavaApp/libs_caciocavallo* $(WORKINGDIR)/PojavLauncher.app/ || exit 1
	@cp -R $(SOURCEDIR)/Natives/*.lproj $(WORKINGDIR)/PojavLauncher.app/ || exit 1
	$(call DIRCHECK,$(OUTPUTDIR))
	@cp -R $(WORKINGDIR)/PojavLauncher.app $(OUTPUTDIR)
	ldid -S$(SOURCEDIR)/entitlements.xml $(OUTPUTDIR)/PojavLauncher.app/PojavLauncher; \
	rm -f $(OUTPUTDIR)/*.ipa; \
	cd $(OUTPUTDIR); \
	$(call DIRCHECK,Payload); \
	mv PojavLauncher.app Payload/; \
	chmod -R 755 Payload; \
	sudo chown -R 501:501 Payload; \
	zip --symlinks -r $(OUTPUTDIR)/net.kdt.pojavlauncher-$(VERSION).ipa Payload/*
	@echo '[PojavLauncher v$(VERSION)] package - end'

dsym: package
	@echo '[PojavLauncher v$(VERSION)] dsym - start'
	@cd $(OUTPUTDIR) && dsymutil --arch arm64 $(OUTPUTDIR)/PojavLauncher.app/PojavLauncher
	@rm -rf $(OUTPUTDIR)/PojavLauncher.dSYM
	@mv $(OUTPUTDIR)/PojavLauncher.app/PojavLauncher.dSYM $(OUTPUTDIR)/PojavLauncher.dSYM
	@rm -rf $(OUTPUTDIR)/PojavLauncher.app
	@echo '[PojavLauncher v$(VERSION)] dsym - end'
	
deploy:
	@echo '[PojavLauncher v$(VERSION)] deploy - start'
	ldid -S$(SOURCEDIR)/entitlements.xml $(WORKINGDIR)/PojavLauncher.app/PojavLauncher; \
	sudo rm -rf /Applications/PojavLauncher.app/Frameworks/libOSMesaOverride.dylib.framework; \
	sudo mv $(WORKINGDIR)/*.dylib /Applications/PojavLauncher.app/Frameworks/; \
	sudo mv $(WORKINGDIR)/*.framework /Applications/PojavLauncher.app/Frameworks/; \
	sudo mv $(WORKINGDIR)/PojavLauncher.app/PojavLauncher /Applications/PojavLauncher.app/PojavLauncher; \
	sudo mv $(SOURCEDIR)/JavaApp/local_out/*.jar /Applications/PojavLauncher.app/libs/; \
	cd /Applications/PojavLauncher.app/Frameworks; \
	sudo chown -R 501:501 /Applications/PojavLauncher.app/*
	@echo '[PojavLauncher v$(VERSION)] deploy - end'

clean:
	@echo '[PojavLauncher v$(VERSION)] clean - start'
	@if [ '$(NOSTDIN)' = '1' ]; then \
		echo '$(SUDOPASS)' | sudo -S rm -rf $(WORKINGDIR); \
		echo '$(SUDOPASS)' | sudo -S rm -rf JavaApp/build; \
		echo '$(SUDOPASS)' | sudo -S rm -rf $(OUTPUTDIR); \
	else \
		sudo rm -rf $(WORKINGDIR); \
		sudo rm -rf JavaApp/build; \
		sudo rm -rf $(OUTPUTDIR); \
	fi
	@echo '[PojavLauncher v$(VERSION)] clean - end'

help:
	@echo 'Makefile to compile PojavLauncher'
	@echo ''
	@echo 'Usage:'
	@echo '    make                                Makes everything under all'
	@echo '    make help                           Displays this message'
	@echo '    make all                            Builds the entire app'
	@echo '    make native                         Builds the native app'
	@echo '    make java                           Builds the Java app'
	@echo '    make jre                            Downloads/unpacks the iOS JREs'
	@echo '    make package                        Builds ipa of PojavLauncher'
	@echo '    make deploy                         Copies files to local iDevice'
	@echo '    make dsym                           Generate debug symbol files'
	@echo '    make clean                          Cleans build directories'
	@echo '    make check                          Dump all variables for checking'

.PHONY: all clean check native java jre package dsym deploy 
