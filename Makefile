SHELL := /bin/bash
.SHELLFLAGS = -ec
# Use `make VERBOSE=1` to print commands.
$(VERBOSE).SILENT:

# Prerequisite variables
SOURCEDIR   := $(shell printf "%q\n" "$(shell pwd)")
OUTPUTDIR   := $(SOURCEDIR)/artifacts
WORKINGDIR  := $(SOURCEDIR)/Natives/build
DETECTPLAT  := $(shell uname -s)
DETECTARCH  := $(shell uname -m)
VERSION     := 2.2
BRANCH      := $(shell git branch --show-current)
COMMIT      := $(shell git log --oneline | sed '2,10000000d' | cut -b 1-7)
PLATFORM    ?= 2

# Release vs Debug
RELEASE ?= 0

# Check if running on github runner
RUNNER ?= 0

# Check if slimmed should be built
SLIMMED ?= 0

# Check if slimmed should be built, and additionally skip normal build
SLIMMED_ONLY ?= 0

# If not in a GitHub repository, default to these
# so that compiling doesn't fail
BRANCH ?= "unknown"
COMMIT ?= "unknown"

# Team IDs and provisioning profile for the codesign function
# Default to -1 for check
# Currently requires a paid Apple Developer account, will fix later
SIGNING_TEAMID ?= -1
TEAMID ?= -1
PROVISIONING ?= -1

ifeq (1,$(RELEASE))
CMAKE_BUILD_TYPE := Release
else
CMAKE_BUILD_TYPE := Debug
endif


# Distinguish iOS from macOS, and *OS from others
ifeq ($(DETECTPLAT),Darwin)
OSVER       := $(shell sw_vers -productVersion | cut -b 1-2)
ifeq ($(shell sw_vers -productName),macOS)
IOS         := 0
SDKPATH     ?= $(shell xcrun --sdk iphoneos --show-sdk-path)
BOOTJDK     ?= $(shell /usr/libexec/java_home -v 1.8)/bin
$(warning Building on macOS.)
else
IOS         := 1
SDKPATH     ?= /usr/share/SDKs/iPhoneOS.sdk
BOOTJDK     ?= /usr/lib/jvm/java-8-openjdk/bin
ifeq ($(shell test "$(OSVER)" -gt 14; echo $$?),0)
PREFIX      ?= /var/jb/
else
PREFIX      ?= /
endif
$(warning Building on iOS. Note that all targets may not compile or require external components.)
endif
else ifeq ($(DETECTPLAT),Linux)
IOS         := 0
# SDKPATH presence is checked later
BOOTJDK     ?= /usr/bin
$(warning Building on Linux. Note that all targets may not compile or require external components.)
else
$(error This platform is not currently supported for building PojavLauncher)
endif

# Define PLATFORM_NAME from PLATFORM
ifeq ($(PLATFORM),2)
PLATFORM_NAME := ios
$(warning Set PLATFORM to 2, which is equal to iOS.)
else ifeq ($(PLATFORM),3)
PLATFORM_NAME := tvos
$(warning Set PLATFORM to 3, which is equal to tvOS.)
else ifeq ($(PLATFORM),7)
PLATFORM_NAME := iossimulator
$(warning Set PLATFORM to 7, which is equal to iOS Simulator.)
else ifeq ($(PLATFORM),8)
PLATFORM_NAME := tvossimulator
$(warning Set PLATFORM to 8, which is equal to tvOS Simulator.)
else
$(error PLATFORM is not valid.)
endif

POJAV_BUNDLE_DIR      ?= $(OUTPUTDIR)/PojavLauncher.app
POJAV_JRE8_DIR        ?= $(SOURCEDIR)/depends/java-8-openjdk
POJAV_JRE17_DIR       ?= $(SOURCEDIR)/depends/java-17-openjdk

# Function to use later for checking dependencies
METHOD_DEPCHECK   = $(shell $(1) >/dev/null 2>&1 && echo 1)

# Function to modify Info.plist files
METHOD_INFOPLIST  =  \
	if [ '$(4)' = '0' ]; then \
		plutil -replace $(1) -string $(2) $(3); \
	else \
		plutil -value $(2) -key $(1) $(3); \
	fi

# Function to check directories
METHOD_DIRCHECK   = \
	if [ ! -d '$(1)' ]; then \
		mkdir -p $(1); \
	else \
		rm -rf $(1)/*; \
	fi
	
# Function to change the platform on Mach-O files.
# iOS = 2, tvOS = 3, iOS Simulator = 7, tvOS Simulator = 8
METHOD_CHANGE_PLAT = \
	vtool -arch arm64 -set-build-version $(1) 12.0 16.0 -replace -output $(2) $(2)
	
# Function to package the application
METHOD_PACKAGE = \
	if [ '$(SLIMMED_ONLY)' = '0' ]; then \
		zip --symlinks -r $(OUTPUTDIR)/net.kdt.pojavlauncher-$(VERSION)-$(PLATFORM_NAME).ipa Payload; \
	fi; \
	if [ '$(SLIMMED)' = '1' ] || [ '$(SLIMMED_ONLY)' = '1' ]; then \
		zip --symlinks -r $(OUTPUTDIR)/net.kdt.pojavlauncher.slimmed-$(VERSION)-$(PLATFORM_NAME).ipa Payload --exclude='Payload/PojavLauncher.app/java_runtimes/*'; \
	fi

# Function to download and unpack Java runtimes.
METHOD_JAVA_UNPACK = \
	cd $(SOURCEDIR)/depends; \
	if [ ! -f "java-$(1)-openjdk/release" ] && [ ! -f "$(ls jre$(1)-*.tar.xz)" ]; then \
		if [ "$(RUNNER)" != "1" ]; then \
			wget '$(2)' -q --show-progress; \
			unzip jre*-ios-aarch64.zip && rm jre*-ios-aarch64.zip; \
		fi; \
		mkdir -p java-$(1)-openjdk; \
		tar xvf jre$(1)-*.tar.xz -C java-$(1)-openjdk; \
	fi

# Function to codesign binaries.
METHOD_CODESIGN = \
	codesign --remove-signature $(2); \
	codesign -f -s $(1) --generate-entitlement-der --entitlements entitlements.codesign.xml $(2); \
	printf 'File: '; printf $(2); printf ', Codesigned with team: '; printf $(1); printf '\n'

# Function to run code when finding Mach-O files.
METHOD_MACHO = \
	for file in $$(find $(1)); do \
		if [[ "$$(file $$file)" == *"Mach-O"* ]]; then \
			$(2); \
		fi; \
	done

# Make sure everything is already available for use. Error if they require something
ifneq ($(call METHOD_DEPCHECK,cmake --version),1)
$(error You need to install cmake)
endif

ifneq ($(call METHOD_DEPCHECK,$(BOOTJDK)/javac -version),1)
$(error You need to install JDK 8)
endif

ifeq ($(IOS),0)
ifeq ($(filter 1.8.0,$(shell $(BOOTJDK)/javac -version &> javaver.txt && cat javaver.txt | cut -b 7-11 && rm -rf javaver.txt)),)
$(error You need to install JDK 8)
endif
endif

ifneq ($(call METHOD_DEPCHECK,ldid),1)
$(error You need to install ldid)
endif

ifneq ($(call METHOD_DEPCHECK,wget --version),1)
$(error You need to install wget)
endif

ifeq ($(DETECTPLAT),Linux)
ifneq ($(call METHOD_DEPCHECK,lld),1)
$(error You need to install lld)
endif
endif

ifneq ($(call METHOD_DEPCHECK,nproc --version),1)
ifneq ($(call METHOD_DEPCHECK,gnproc --version),1)
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

all: clean native java jre assets payload package dsym

help:
	echo 'Makefile to compile PojavLauncher'
	echo ''
	echo 'Usage:'
	echo '    make                                Makes everything under all'
	echo '    make help                           Displays this message'
	echo '    make all                            Builds the entire app'
	echo '    make native                         Builds the native app'
	echo '    make java                           Builds the Java app'
	echo '    make jre                            Downloads/unpacks the iOS JREs'
	echo '    make assets                         Compiles Assets.xcassets'
	echo '    make payload                        Makes Payload/PojavLauncher.app'
	echo '    make package                        Builds ipa of PojavLauncher'
	echo '    make deploy                         Copies files to local iDevice'
	echo '    make dsym                           Generate debug symbol files'
	echo '    make clean                          Cleans build directories'
	echo '    make check                          Dump all variables for checking'

check:
	$(foreach v, \
		$(shell echo "$(filter-out METHOD_% .% MAKEFILE_LIST MAKEFLAGS CURDIR,$(.VARIABLES))" | tr ' ' '\n' | sort), \
		$(if $(filter file,$(origin $(v))), \
		$(info $(shell printf "%-20s" "$(v)") = $(value $(v)))) \
	)

native:
	echo '[PojavLauncher v$(VERSION)] native - start'
	mkdir -p $(WORKINGDIR)
	cd $(WORKINGDIR) && cmake . \
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

	cmake --build $(WORKINGDIR) --config $(CMAKE_BUILD_TYPE) -j$(JOBS)
	#	--target awt_headless awt_xawt libOSMesaOverride.dylib tinygl4angle PojavLauncher
	rm $(WORKINGDIR)/libawt_headless.dylib
	echo '[PojavLauncher v$(VERSION)] native - end'

java:
	echo '[PojavLauncher v$(VERSION)] java - start'
	cd $(SOURCEDIR)/JavaApp; \
	mkdir -p local_out/classes; \
	$(BOOTJDK)/javac -cp "libs/*:libs_caciocavallo/*" -d local_out/classes $$(find src -type f -name "*.java" -print) -XDignore.symbol.file || exit 1; \
	cd local_out/classes; \
	$(BOOTJDK)/jar -cf ../launcher.jar android com net || exit 1; \
	cp $(SOURCEDIR)/JavaApp/libs/lwjgl3-minecraft.jar ../lwjgl3-minecraft.jar || exit 1; \
	$(BOOTJDK)/jar -uf ../lwjgl3-minecraft.jar org || exit 1;
	echo '[PojavLauncher v$(VERSION)] java - end'

jre: native
	echo '[PojavLauncher v$(VERSION)] jre - start'
	mkdir -p $(SOURCEDIR)/depends
	cd $(SOURCEDIR)/depends; \
	$(call METHOD_JAVA_UNPACK,8,'https://nightly.link/PojavLauncherTeam/android-openjdk-build-multiarch/workflows/build/jre8-ios-jitjailed/jre8-ios-aarch64.zip'); \
	$(call METHOD_JAVA_UNPACK,17,'https://nightly.link/PojavLauncherTeam/android-openjdk-build-multiarch/workflows/build/buildjre17/jre17-ios-aarch64.zip'); \
	if [ -f "$(ls jre*.tar.xz)" ]; then rm $(SOURCEDIR)/depends/jre*.tar.xz; fi; \
	cd $(SOURCEDIR); \
	rm -rf $(SOURCEDIR)/depends/java-*-openjdk/{ASSEMBLY_EXCEPTION,bin,include,jre,legal,LICENSE,man,THIRD_PARTY_README,lib/{ct.sym,libjsig.dylib,src.zip,tools.jar}}; \
	$(call METHOD_DIRCHECK,$(OUTPUTDIR)/java_runtimes); \
	cp -R $(POJAV_JRE8_DIR) $(OUTPUTDIR)/java_runtimes; \
	cp -R $(POJAV_JRE17_DIR) $(OUTPUTDIR)/java_runtimes; \
	cp $(WORKINGDIR)/libawt_xawt.dylib $(OUTPUTDIR)/java_runtimes/java-8-openjdk/lib; \
	cp $(WORKINGDIR)/libawt_xawt.dylib $(OUTPUTDIR)/java_runtimes/java-17-openjdk/lib
	echo '[PojavLauncher v$(VERSION)] jre - end'

assets:
	echo '[PojavLauncher v$(VERSION)] assets - start'
	if [ '$(IOS)' = '0' ] && [ '$(DETECTPLAT)' = 'Darwin' ]; then \
		mkdir -p $(WORKINGDIR)/PojavLauncher.app/Base.lproj; \
		xcrun actool $(SOURCEDIR)/Natives/Assets.xcassets \
			--compile $(SOURCEDIR)/Natives/resources \
			--platform iphoneos \
			--minimum-deployment-target 12.0 \
			--app-icon AppIcon-Light \
			--alternate-app-icon AppIcon-Dark \
			--alternate-app-icon AppIcon-Development \
			--output-partial-info-plist /dev/null || exit 1; \
	else \
		echo 'Due to the required tools not being available, you cannot compile the extras for PojavLauncher with an iOS device.'; \
	fi
	echo '[PojavLauncher v$(VERSION)] assets - end'

payload: native java jre assets
	echo '[PojavLauncher v$(VERSION)] payload - start'
	$(call METHOD_DIRCHECK,$(WORKINGDIR)/PojavLauncher.app/libs)
	$(call METHOD_DIRCHECK,$(WORKINGDIR)/PojavLauncher.app/libs_caciocavallo)
	$(call METHOD_DIRCHECK,$(WORKINGDIR)/PojavLauncher.app/libs_caciocavallo17)
	cp -R $(SOURCEDIR)/Natives/resources/en.lproj/LaunchScreen.storyboardc $(WORKINGDIR)/PojavLauncher.app/Base.lproj/ || exit 1
	cp -R $(SOURCEDIR)/Natives/resources/* $(WORKINGDIR)/PojavLauncher.app/ || exit 1
	cp $(WORKINGDIR)/*.dylib $(WORKINGDIR)/PojavLauncher.app/Frameworks/ || exit 1
	cp -R $(SOURCEDIR)/JavaApp/libs/* $(WORKINGDIR)/PojavLauncher.app/libs/ || exit 1
	cp $(SOURCEDIR)/JavaApp/local_out/*.jar $(WORKINGDIR)/PojavLauncher.app/libs/ || exit 1
	cp -R $(SOURCEDIR)/JavaApp/libs_caciocavallo* $(WORKINGDIR)/PojavLauncher.app/ || exit 1
	$(call METHOD_DIRCHECK,$(OUTPUTDIR)/Payload)
	cp -R $(WORKINGDIR)/PojavLauncher.app $(OUTPUTDIR)/Payload
	if [ '$(SLIMMED_ONLY)' != '1' ]; then \
		cp -R $(OUTPUTDIR)/java_runtimes $(OUTPUTDIR)/Payload/PojavLauncher.app; \
	fi
	ldid -S $(OUTPUTDIR)/Payload/PojavLauncher.app; \
	ldid -S$(SOURCEDIR)/entitlements.xml $(OUTPUTDIR)/Payload/PojavLauncher.app/PojavLauncher; \
	chmod -R 755 $(OUTPUTDIR)/Payload
	if [ '$(PLATFORM)' != '2' ]; then \
		$(call METHOD_MACHO,$(OUTPUTDIR)/Payload/PojavLauncher.app,$(call METHOD_CHANGE_PLAT,$(PLATFORM),$$file)); \
		$(call METHOD_MACHO,$(OUTPUTDIR)/java_runtimes,$(call METHOD_CHANGE_PLAT,$(PLATFORM),$$file)); \
	fi
	echo '[PojavLauncher v$(VERSION)] payload - end'

deploy:
	echo '[PojavLauncher v$(VERSION)] deploy - start'
	cd $(OUTPUTDIR); \
	if [ '$(IOS)' = '1' ]; then \
		ldid -S $(WORKINGDIR)/PojavLauncher.app || exit 1; \
		ldid -S$(SOURCEDIR)/entitlements.xml $(WORKINGDIR)/PojavLauncher.app/PojavLauncher || exit 1; \
		sudo mv $(WORKINGDIR)/*.dylib $(PREFIX)Applications/PojavLauncher.app/Frameworks/ || exit 1; \
		sudo mv $(WORKINGDIR)/PojavLauncher.app/PojavLauncher $(PREFIX)Applications/PojavLauncher.app/PojavLauncher || exit 1; \
		sudo mv $(SOURCEDIR)/JavaApp/local_out/*.jar $(PREFIX)Applications/PojavLauncher.app/libs/ || exit 1; \
		cd $(PREFIX)Applications/PojavLauncher.app/Frameworks || exit 1; \
		sudo chown -R 501:501 $(PREFIX)Applications/PojavLauncher.app/* || exit 1; \
	elif [ '$(IOS)' = '0' ] && [ '$(DETECTPLAT)' = 'Darwin' ]; then \
		if [ '$(PLATFORM)' != '2' ] || [ '$(TEAMID)' = '-1' ] || [ '$(SIGNING_TEAMID)' = '-1' ] || [ '$(PROVISIONING)' = '-1' ]; then \
			echo 'Configuration not supported for deploy recipe.'; \
		else \
			$(call METHOD_PACKAGE); \
			if [ '$(SLIMMED_ONLY)' = '0' ]; then \
				open $(OUTPUTDIR)/net.kdt.pojavlauncher-$(VERSION)-$(PLATFORM_NAME).ipa; \
			else \
				open $(OUTPUTDIR)/net.kdt.pojavlauncher.slimmed-$(VERSION)-$(PLATFORM_NAME).ipa; \
			fi; \
		fi; \
	else \
		echo 'Device not supported for deploy recipe.'; \
	fi
	echo '[PojavLauncher v$(VERSION)] deploy - end'

package: payload
	echo '[PojavLauncher v$(VERSION)] package - start'
	if [ '$(TEAMID)' != '-1' ] && [ '$(SIGNING_TEAMID)' != '-1' ] && [ -f '$(PROVISIONING)' ] && [ '$(DETECTPLAT)' = 'Darwin' ]; then \
		printf '<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n<plist version="1.0">\n<dict>\n	<key>application-identifier</key>\n	<string>$(TEAMID).net.kdt.pojavlauncher</string>\n	<key>com.apple.developer.team-identifier</key>\n	<string>$(TEAMID)</string>\n	<key>get-task-allow</key>\n	<true/>\n	<key>keychain-access-groups</key>\n	<array>\n	<string>$(TEAMID).*</string>\n	<string>com.apple.token</string>\n	</array>\n</dict>\n</plist>' > entitlements.codesign.xml; \
		$(MAKE) codesign; \
		rm -rf entitlements.codesign.xml; \
	else \
		echo 'Skipped codesigning. If not intentional, check your variables.'; \
	fi
	cd $(OUTPUTDIR); \
	$(call METHOD_PACKAGE); \
	zip --symlinks -r $(OUTPUTDIR)/java_runtimes.zip java_runtimes; \
	echo '[PojavLauncher v$(VERSION)] package - end'
	
dsym: payload
	echo '[PojavLauncher v$(VERSION)] dsym - start'
	dsymutil --arch arm64 $(OUTPUTDIR)/Payload/PojavLauncher.app/PojavLauncher; \
	rm -rf $(OUTPUTDIR)/PojavLauncher.dSYM; \
	mv $(OUTPUTDIR)/Payload/PojavLauncher.app/PojavLauncher.dSYM $(OUTPUTDIR)/PojavLauncher.dSYM
	echo '[PojavLauncher v$(VERSION)] dsym - end'
	
codesign:
	echo '[PojavLauncher v$(VERSION)] codesign - start'
	cp '$(PROVISIONING)' $(OUTPUTDIR)/Payload/PojavLauncher.app/embedded.mobileprovision
	$(call METHOD_MACHO,$(OUTPUTDIR)/Payload/PojavLauncher.app,$(call METHOD_CODESIGN,$(SIGNING_TEAMID),$$file))
	$(call METHOD_MACHO,$(OUTPUTDIR)/java_runtimes,$(call METHOD_CODESIGN,$(SIGNING_TEAMID),$$file))
	echo '[PojavLauncher v$(VERSION)] codesign - end'
clean:
	echo '[PojavLauncher v$(VERSION)] clean - start'
	rm -rf $(WORKINGDIR)
	rm -rf JavaApp/build
	rm -rf $(OUTPUTDIR)
	echo '[PojavLauncher v$(VERSION)] clean - end'

.PHONY: all clean check native java jre package dsym deploy help
