SHELL := /bin/bash
.SHELLFLAGS = -ec

# Prerequisite variables
SOURCEDIR   := $(shell printf "%q\n" "$(shell pwd)")
OUTPUTDIR   := $(SOURCEDIR)/artifacts
WORKINGDIR  := $(SOURCEDIR)/Natives/build
DETECTPLAT  := $(shell uname -s)
DETECTARCH  := $(shell uname -m)
VERSION     := $(shell cat $(SOURCEDIR)/DEBIAN/control.development | grep Version | cut -b 10-60)
BRANCH      := $(shell git branch --show-current)
COMMIT      := $(shell git log --oneline | sed '2,10000000d' | cut -b 1-7)
IOS15PREF   := private/preboot/procursus

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
BOOTJDK     ?= /usr/bin
ifneq (,$(findstring arm,DETECTARCH))
SYSARCH     := arm
$(warning Building on an Apple-Silicon Mac.)
else ifneq (,$(findstring 86,$(DETECTARCH)))
SYSARCH     := x86_64
$(warning Building on an Intel or AMD-based Mac.)
endif
ifdef DEVICE_IP
DEVICE_PORT ?= 22
endif
else
IOS         := 1
SDKPATH     ?= /usr/share/SDKs/iPhoneOS.sdk
BOOTJDK     ?= /usr/lib/jvm/java-8-openjdk/bin
SYSARCH     := arm
DEVICE_IP   ?= 127.0.0.1
DEVICE_PORT ?= 22
$(warning Building on a jailbroken iOS device.)
endif
else ifeq ($(DETECTPLAT),Linux)
$(warning Building on Linux. Note that all targets may not compile or require external components.)
IOS         := 0
# SDKPATH presence is checked later
BOOTJDK     ?= /usr/bin
SYSARCH     := $(shell uname -m)
else
$(error This platform is not currently supported for building PojavLauncher.)
endif

# IPABuilder depending variables
ifeq ($(IOS),1)
POJAV_BUNDLE_DIR    ?= /Applications/PojavLauncher.app
POJAV_JRE8_DIR       ?= /usr/lib/jvm/java-8-openjdk
# POJAV_JRE17_DIR       ?= /usr/lib/jvm/java-17-openjdk
else
POJAV_BUNDLE_DIR    ?= $(OUTPUTDIR)/PojavLauncher.app
POJAV_JRE8_DIR       ?= $(SOURCEDIR)/depends/java-8-openjdk
POJAV_JRE17_DIR       ?= $(SOURCEDIR)/depends/java-17-openjdk
endif

# Function to use later for checking dependencies
DEPCHECK   = $(shell $(1) >/dev/null 2>&1 && echo 1)

# Function to modify Info.plist files
INFOPLIST  =  \
	if [ '$(4)' = '0' ]; then \
		plutil -replace $(1) -string $(2) $(3); \
	else \
		plutil -value $(2) -key $(1) $(3); \
	fi

# Function to use for packaging
PACKAGING  =  \
	mkdir -p $(OUTPUTDIR)/net.kdt.pojavlauncher.$(1)_$(VERSION)_iphoneos-arm; \
	cd $(OUTPUTDIR)/net.kdt.pojavlauncher.$(1)_$(VERSION)_iphoneos-arm; \
	mkdir -p {DEBIAN,Applications,usr/share/pojavlauncher/{accounts,instances/default,Library/{Application\ Support,Caches}}}; \
	cd usr/share/pojavlauncher; \
	ln -sf ../../instances/default Library/Application\ Support/minecraft; \
	cd $(OUTPUTDIR)/net.kdt.pojavlauncher.$(1)_$(VERSION)_iphoneos-arm; \
	if [ '$(NOSTDIN)' = '1' ]; then \
		echo '$(SUDOPASS)' | sudo -S chown -R 501:501 usr/share/pojavlauncher; \
	else \
		sudo chown -R 501:501 usr/share/pojavlauncher; \
	fi; \
	cp -r $(OUTPUTDIR)/PojavLauncher.app Applications/PojavLauncher.app; \
	cp $(SOURCEDIR)/DEBIAN/control.$(1) DEBIAN/control; \
	cp $(SOURCEDIR)/DEBIAN/postinst DEBIAN/postinst; \
	ldid -S$(SOURCEDIR)/entitlements.xml Applications/PojavLauncher.app; \
	cd $(OUTPUTDIR); \
	fakeroot dpkg-deb -Zxz -b $(OUTPUTDIR)/net.kdt.pojavlauncher.$(1)_$(VERSION)_iphoneos-arm; \
	mkdir -p $(OUTPUTDIR)/net.kdt.pojavlauncher.$(1)-rootless_$(VERSION)_iphoneos-arm64; \
	cd $(OUTPUTDIR)/net.kdt.pojavlauncher.$(1)-rootless_$(VERSION)_iphoneos-arm64; \
	mkdir -p {DEBIAN,$(IOS15PREF)/{Applications,usr/share/pojavlauncher/{accounts,instances/default,Library/{Application\ Support,Caches}}}}; \
	cd $(IOS15PREF)/usr/share/pojavlauncher; \
	ln -sf ../../instances/default Library/Application\ Support/minecraft; \
	cd $(OUTPUTDIR)/net.kdt.pojavlauncher.$(1)-rootless_$(VERSION)_iphoneos-arm64; \
	if [ '$(NOSTDIN)' = '1' ]; then \
		echo '$(SUDOPASS)' | sudo -S chown -R 501:501 $(IOS15PREF)/usr/share/pojavlauncher; \
	else \
		sudo chown -R 501:501 $(IOS15PREF)/usr/share/pojavlauncher; \
	fi; \
	cp -r $(OUTPUTDIR)/PojavLauncher.app $(IOS15PREF)/Applications/PojavLauncher.app; \
	cp -r $(SOURCEDIR)/DEBIAN/control.$(1)-rootless DEBIAN/control; \
	cp $(SOURCEDIR)/DEBIAN/postinst DEBIAN/postinst; \
	ldid -S$(SOURCEDIR)/entitlements.xml $(IOS15PREF)/Applications/PojavLauncher.app; \
	cd $(OUTPUTDIR); \
	fakeroot dpkg-deb -Zxz -b $(OUTPUTDIR)/net.kdt.pojavlauncher.$(1)-rootless_$(VERSION)_iphoneos-arm64

# Function to check directories
DIRCHECK   = \
	if [ ! -d '$(1)' ]; then \
		mkdir $(1); \
	else \
		sudo rm -rf $(1)/*; \
	fi

# Function to copy + install
INSTALL    = \
	echo 'Please note that this may not work properly. If it doesn'\''t work for you, you can manually extract the .deb in /var/tmp/net.kdt.pojavlauncher.$(1)_$(VERSION)_$(2).deb with dpkg or Filza.'; \
	if [ '$(4)' = '0' ]; then \
		scp -P $(DEVICE_PORT) $(OUTPUTDIR)/net.kdt.pojavlauncher.$(1)_$(VERSION)_$(2).deb root@$(DEVICE_IP):/var/tmp/net.kdt.pojavlauncher.$(1)_$(VERSION)_$(2).deb; \
		ssh root@$(DEVICE_IP) -p $(DEVICE_PORT) -t "dpkg -i /var/tmp/net.kdt.pojavlauncher.$(1)_$(VERSION)_$(2).deb; uicache -p $(3)/Applications/PojavLauncher.app"; \
	else \
		sudo dpkg -i $(OUTPUTDIR)/net.kdt.pojavlauncher.$(1)_$(VERSION)_$(2).deb; uicache -p $(3)/Applications/PojavLauncher.app; \
	fi

# Function to copy + deploy
DEPLOY     = \
	ldid -S$(SOURCEDIR)/entitlements.xml $(WORKINGDIR)/PojavLauncher.app/PojavLauncher; \
	if [ '$(2)' = '0' ]; then \
		scp -r -P $(DEVICE_PORT) -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" \
			$(WORKINGDIR)/*.framework \
			$(WORKINGDIR)/*.dylib \
			$(WORKINGDIR)/PojavLauncher.app/PojavLauncher \
			$(SOURCEDIR)/JavaApp/local_out/*.jar \
			root@$(DEVICE_IP):/var/tmp/; \
		ssh root@$(DEVICE_IP) -p $(DEVICE_PORT) -t " \
			mv /var/tmp/*.dylib $(1)/Applications/PojavLauncher.app/Frameworks/ && \
			mv /var/tmp/*.framework $(1)/Applications/PojavLauncher.app/Frameworks/ && \
			mv /var/tmp/PojavLauncher $(1)/Applications/PojavLauncher.app/PojavLauncher && \
			mv /var/tmp/*.jar $(1)/Applications/PojavLauncher.app/libs/ && \
			cd $(1)/Applications/PojavLauncher.app/Frameworks && \
			chown -R 501:501 $(1)/Applications/PojavLauncher.app/*"; \
	else \
		sudo rm -rf $(1)/Applications/PojavLauncher.app/Frameworks/libOSMesaOverride.dylib.framework; \
		sudo mv $(WORKINGDIR)/*.dylib $(1)/Applications/PojavLauncher.app/Frameworks/; \
		sudo mv $(WORKINGDIR)/*.framework $(1)/Applications/PojavLauncher.app/Frameworks/; \
		sudo mv $(WORKINGDIR)/PojavLauncher.app/PojavLauncher $(1)/Applications/PojavLauncher.app/PojavLauncher; \
		sudo mv $(SOURCEDIR)/JavaApp/local_out/*.jar $(1)/Applications/PojavLauncher.app/libs/; \
		cd $(1)/Applications/PojavLauncher.app/Frameworks; \
		sudo chown -R 501:501 $(1)/Applications/PojavLauncher.app/*; \
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

ifneq ($(call DEPCHECK,fakeroot -v),1)
$(error You need to install fakeroot)
endif

ifneq ($(call DEPCHECK,dpkg-deb --version),1)
$(error You need to install dpkg-dev)
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
#  extras  - Builds the Assets and Storyboard.
#  deb     - Builds the Debian package. Will be removed in 2.2.
#  ipa     - Builds the application package.
#  install - runs deb + installs to jailbroken device. Will be removed in 2.2.
#  deploy  - runs native and java + installs to jailbroken device. Will be removed in 2.2.
#  dsym    - Generates debug symbol files

all: clean native java extras deb dsym ipa

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
	@printf 'IOS15PREF            - $(IOS15PREF)\n'
	@printf 'IOS                  - $(IOS)\n'
	@printf 'SYSARCH              - $(SYSARCH)\n'
	@printf 'POJAV_BUNDLE_DIR     - $(POJAV_BUNDLE_DIR)\n'
	@printf 'POJAV_JRE_DIR        - $(POJAV_JRE_DIR)\n'
	@printf 'DEVICE_IP            - $(DEVICE_IP)\n'
	@printf 'DEVICE_PORT          - $(DEVICE_PORT)\n'
	@printf '\nVerify that all of the variables are correct.\n'
	
native:
	@echo 'Building PojavLauncher $(VERSION) - NATIVES - Start'
	@mkdir -p $(WORKINGDIR)
	@cd $(WORKINGDIR) && cmake . \
		-DCMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE) \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_SYSTEM_PROCESSOR=aarch64 \
		-DCMAKE_OSX_SYSROOT="$(SDKPATH)" \
		-DCMAKE_OSX_ARCHITECTURES=arm64 \
		-DCMAKE_C_FLAGS="-arch arm64 -miphoneos-version-min=12.0" \
		-DCONFIG_BRANCH="$(BRANCH)" \
		-DCONFIG_COMMIT="$(COMMIT)" \
		-DCONFIG_RELEASE=$(RELEASE) \
		..

	@cmake --build $(WORKINGDIR) --config $(CMAKE_BUILD_TYPE) -j$(JOBS)
	@# --target awt_headless awt_xawt libOSMesaOverride.dylib tinygl4angle PojavLauncher
	@rm $(WORKINGDIR)/libawt_headless.dylib
	@echo 'Building PojavLauncher $(VERSION) - NATIVES - End'

java:
	@echo 'Building PojavLauncher $(VERSION) - JAVA - Start'
	@cd $(SOURCEDIR)/JavaApp; \
	mkdir -p local_out/classes; \
	$(BOOTJDK)/javac -cp "libs/*:libs_caciocavallo/*" -d local_out/classes $$(find src -type f -name "*.java" -print) -XDignore.symbol.file || exit 1; \
	cd local_out/classes; \
	$(BOOTJDK)/jar -cf ../launcher.jar android com net || exit 1; \
	cp $(SOURCEDIR)/JavaApp/libs/lwjgl3-minecraft.jar ../lwjgl3-minecraft.jar || exit 1; \
	$(BOOTJDK)/jar -uf ../lwjgl3-minecraft.jar org || exit 1;
	@echo 'Building PojavLauncher $(VERSION) - JAVA - End'

extras:
	@echo 'Building PojavLauncher $(VERSION) - EXTRA - Start'
	@if [ '$(IOS)' = '0' ]; then \
		mkdir -p $(WORKINGDIR)/PojavLauncher.app/Base.lproj; \
		xcrun actool $(SOURCEDIR)/Natives/Assets.xcassets --compile $(SOURCEDIR)/Natives/resources --platform iphoneos --minimum-deployment-target 12.0 --app-icon AppIcon --output-partial-info-plist /dev/null || exit 1; \
		ibtool --compile $(WORKINGDIR)/PojavLauncher.app/Base.lproj/LaunchScreen.storyboardc $(SOURCEDIR)/Natives/en.lproj/LaunchScreen.storyboard || exit 1; \
	elif [ '$(IOS)' = '1' ]; then \
		echo 'Due to the required tools not being available, you cannot compile the extras for PojavLauncher with an iOS device.'; \
	fi
	@echo 'Building PojavLauncher $(VERSION) - EXTRAS - End'

deb: native java extras
	@echo 'Building PojavLauncher $(VERSION) - DEB - Start'
	@if [ '$(IOS)' = '1' ]; then \
		mkdir -p $(WORKINGDIR)/PojavLauncher.app/{Frameworks,Base.lproj}; \
		cp -R $(SOURCEDIR)/Natives/en.lproj/*.storyboardc $(WORKINGDIR)/PojavLauncher.app/Base.lproj/ || exit 1; \
		cp -R $(SOURCEDIR)/Natives/Info.plist $(WORKINGDIR)/PojavLauncher.app/Info.plist || exit 1;\
		cp -R $(SOURCEDIR)/Natives/PkgInfo $(WORKINGDIR)/PojavLauncher.app/PkgInfo || exit 1; \
	fi
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
	@if [ '$(RELEASE)' = '1' ]; then \
		$(call PACKAGING,release); \
	else \
		$(call PACKAGING,development); \
	fi
	@echo 'Building PojavLauncher $(VERSION) - DEB - End'

dsym: deb
	@echo 'Building PojavLauncher $(VERSION) - DSYM - Start'
	@cd $(OUTPUTDIR) && dsymutil --arch arm64 $(OUTPUTDIR)/PojavLauncher.app/PojavLauncher
	@rm -rf $(OUTPUTDIR)/PojavLauncher.dSYM
	@mv $(OUTPUTDIR)/PojavLauncher.app/PojavLauncher.dSYM $(OUTPUTDIR)/PojavLauncher.dSYM
	@echo 'Building PojavLauncher $(VERSION) - DSYM - Start'

ipa: dsym
	echo 'Building PojavLauncher $(VERSION) - IPA - Start'
	@mkdir -p $(SOURCEDIR)/depends; \
	cd $(SOURCEDIR)/depends; \
	if [ ! -f "java-8-openjdk/bin/java" ] && [ ! -f "$(ls ../jre8-*.tar.xz)" ]; then \
		if [ "$(RUNNER)" != "1" ]; then \
			wget 'https://github.com/PojavLauncherTeam/android-openjdk-build-multiarch/releases/download/jre8-40df388/jre8-arm64-20220811-release.tar.xz' -q --show-progress; \
		fi; \
		mkdir java-8-openjdk && cd java-8-openjdk; \
		tar xvf ../jre8-*.tar.xz; \
		rm ../jre8-*.tar.xz; \
	fi; \
	cd $(SOURCEDIR)/depends; \
	if [ ! -f "java-17-openjdk/bin/java" ] && [ ! -f "$(ls ../jre17-*.tar.xz)" ]; then \
		if [ "$(RUNNER)" != "1" ]; then \
			wget 'https://github.com/PojavLauncherTeam/android-openjdk-build-multiarch/releases/download/jre17-ca01427/jre17-arm64-20220817-release.tar.xz' -q --show-progress; \
		fi; \
		mkdir java-17-openjdk && cd java-17-openjdk; \
		tar xvf ../jre17-*.tar.xz; \
		rm ../jre17-*.tar.xz; \
	fi; \
	cd ..; \
	mkdir -p $(OUTPUTDIR); \
	cd $(OUTPUTDIR); \
	$(call DIRCHECK,$(OUTPUTDIR)/Payload); \
	cp -R $(POJAV_BUNDLE_DIR) $(OUTPUTDIR)/Payload; \
	$(call DIRCHECK,$(OUTPUTDIR)/Payload/PojavLauncher.app/jvm); \
	cp -R $(POJAV_JRE8_DIR) $(OUTPUTDIR)/Payload/PojavLauncher.app/jvm/; \
	cp -R $(POJAV_JRE17_DIR) $(OUTPUTDIR)/Payload/PojavLauncher.app/jvm/; \
	rm -rf $(OUTPUTDIR)/Payload/PojavLauncher.app/jvm/*/{bin,include,jre,lib/{ct.sym,libjsig.dylib,src.zip,tools.jar}}; \
	cp $(OUTPUTDIR)/Payload/PojavLauncher.app/Frameworks/libawt_xawt.dylib $(OUTPUTDIR)/Payload/PojavLauncher.app/jvm/java-17-openjdk/lib/; \
	cp $(OUTPUTDIR)/Payload/PojavLauncher.app/Frameworks/libawt_xawt.dylib $(OUTPUTDIR)/Payload/PojavLauncher.app/jvm/java-8-openjdk/lib/; \
	rm $(OUTPUTDIR)/Payload/PojavLauncher.app/Frameworks/libawt_*.dylib; \
	ldid -S$(SOURCEDIR)/entitlements_ipa.xml $(OUTPUTDIR)/Payload/PojavLauncher.app/PojavLauncher; \
	rm -f $(OUTPUTDIR)/*.ipa; \
	cd $(OUTPUTDIR); \
	chmod -R 755 Payload; \
	sudo chown -R 501:501 Payload; \
	zip --symlinks -r $(OUTPUTDIR)/net.kdt.pojavlauncher-$(VERSION).ipa Payload/*
	@echo 'Building PojavLauncher $(VERSION) - IPA - End'

install: deb
	@echo 'Building PojavLauncher $(VERSION) - INSTALL - Start'
	@if [ '$(DEVICE_IP)' != '' ]; then \
		if [ '$(RELEASE)' = '1' ]; then \
			if [ '$(ROOTLESS)' = '1' ]; then \
				$(call INSTALL,release-rootless,iphoneos-arm64,$(IOS15PREF)); \
			else \
				$(call INSTALL,release,iphoneos-arm); \
			fi; \
		else \
			if [ '$(ROOTLESS)' = '1' ]; then \
				$(call INSTALL,development-rootless,iphoneos-arm64,$(IOS15PREF)); \
			else \
				$(call INSTALL,development,iphoneos-arm); \
			fi; \
		fi; \
	else \
		echo 'You need to run '\''export DEVICE_IP=<your iOS device IP>'\'' to use make install.'; \
		echo 'If you specified a different port for your device to listen for SSH connections, you need to run '\''export DEVICE_PORT=<your port>'\'' as well.'; \
	fi
	@echo 'Building PojavLauncher $(VERSION) - INSTALL - End'

# deb
deploy:
	@echo 'Building PojavLauncher $(VERSION) - DEPLOY - Start'
	@if [ '$(DEVICE_IP)' != '' ]; then \
		if [ '$(ROOTLESS)' = '1' ]; then \
			$(call DEPLOY,$(IOS15PREF),$(IOS)); \
		else \
			$(call DEPLOY,'/',$(IOS)); \
		fi; \
	else \
		echo 'You need to run '\''export DEVICE_IP=<your iOS device IP>'\'' to use make deploy.'; \
		echo 'If you specified a different port for your device to listen for SSH connections, you need to run '\''export DEVICE_PORT=<your port>'\'' as well.'; \
	fi;
	@echo 'Building PojavLauncher $(VERSION) - DEPLOY - End'

clean:
	@echo 'Building PojavLauncher $(VERSION) - CLEAN - Start'
	@if [ '$(NOSTDIN)' = '1' ]; then \
		echo '$(SUDOPASS)' | sudo -S rm -rf $(WORKINGDIR); \
		echo '$(SUDOPASS)' | sudo -S rm -rf JavaApp/build; \
		echo '$(SUDOPASS)' | sudo -S rm -rf $(OUTPUTDIR); \
	else \
		sudo rm -rf $(WORKINGDIR); \
		sudo rm -rf JavaApp/build; \
		sudo rm -rf $(OUTPUTDIR); \
	fi
	@echo 'Building PojavLauncher $(VERSION) - CLEAN - End'

help:
	@echo 'Makefile to compile PojavLauncher'
	@echo ''
	@echo 'Usage:'
	@echo '    make                                Makes everything under all'
	@echo '    make all                            Builds the entire app'
	@echo '    make native                         Builds the native app'
	@echo '    make java                           Builds the Java app'
	@echo '    make deb      (DEPRECATED)          Builds deb of PojavLauncher'
	@echo '    make ipa                            Builds ipa of PojavLauncher'
	@echo '    make install  (DEPRECATED)          Copy package to local iDevice'
	@echo '    make deploy   (DEPRECATED)          Copy package to local iDevice'
	@echo '    make dsym                           Generate debug symbol files'
	@echo '    make clean                          Cleans build directories'

.PHONY: all clean native java extras deb ipa install deploy dsym
