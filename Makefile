SHELL := /bin/bash
.SHELLFLAGS = -ec

# Prerequisite variables
SOURCEDIR   := $(shell pwd)
OUTPUTDIR   := $(SOURCEDIR)/artifacts
WORKINGDIR  := $(SOURCEDIR)/Natives/build
DETECTPLAT  := $(shell uname -s)
DETECTARCH  := $(shell uname -m)
VERSION     := $(shell cat $(SOURCEDIR)/DEBIAN/control.development | grep Version | cut -b 10-60)
COMMIT      := $(shell git log --oneline | sed '2,10000000d' | cut -b 1-7)
IOS15PREF   := private/preboot/procursus

# Release vs Debug
RELEASE ?= 0

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
else
$(error This platform is not currently supported for building PojavLauncher.)
endif

# IPABuilder depending variables
ifeq ($(IOS),1)
POJAV_BUNDLE_DIR    ?= /Applications/PojavLauncher.app
POJAV_JRE_DIR       ?= /usr/lib/jvm/java-8-openjdk
else
POJAV_BUNDLE_DIR    ?= $(OUTPUTDIR)/PojavLauncher.app
POJAV_JRE_DIR       ?= $(SOURCEDIR)/depends/jre
endif
POJAV_BUNDLE_DYLIBS ?= $(shell cd "$(POJAV_BUNDLE_DIR)/Frameworks" && echo *.dylib)
POJAV_JRE_DYLIBS    ?= $(shell cd "$(POJAV_JRE_DIR)" && find . -name "*.dylib")

# Function to use later for checking dependencies
DEPCHECK    = $(shell type $(1) >/dev/null 2>&1 && echo 1)

# Function to use for packaging
PACKAGING  =  \
	mkdir -p $(OUTPUTDIR)/net.kdt.pojavlauncher.$(1)_$(VERSION)_iphoneos-arm; \
	cd $(OUTPUTDIR)/net.kdt.pojavlauncher.$(1)_$(VERSION)_iphoneos-arm; \
	mkdir -p {DEBIAN,Applications,var/mobile/Documents/.pojavlauncher/{instances/default,Library/{Application\ Support,Caches}}}; \
	cd var/mobile/Documents/.pojavlauncher; \
	ln -sf ../../instances/default Library/Application\ Support/minecraft; \
	cd $(OUTPUTDIR)/net.kdt.pojavlauncher.$(1)_$(VERSION)_iphoneos-arm; \
	if [ '$(NOSTDIN)' = '1' ]; then \
		echo '$(SUDOPASS)' | sudo -S chown -R 501:501 var/mobile/Documents/.pojavlauncher; \
	else \
		sudo chown -R 501:501 var/mobile/Documents/.pojavlauncher; \
	fi; \
	cp -r $(OUTPUTDIR)/PojavLauncher.app Applications/PojavLauncher.app; \
	cp $(SOURCEDIR)/DEBIAN/control.$(1) DEBIAN/control; \
	cp $(SOURCEDIR)/DEBIAN/postinst DEBIAN/postinst; \
	ldid -S$(SOURCEDIR)/entitlements.xml Applications/PojavLauncher.app; \
	cd $(OUTPUTDIR); \
	fakeroot dpkg-deb -b $(OUTPUTDIR)/net.kdt.pojavlauncher.$(1)_$(VERSION)_iphoneos-arm; \
	mkdir -p $(OUTPUTDIR)/net.kdt.pojavlauncher.$(1)-rootless_$(VERSION)_iphoneos-arm64; \
	cd $(OUTPUTDIR)/net.kdt.pojavlauncher.$(1)-rootless_$(VERSION)_iphoneos-arm64; \
	mkdir -p {DEBIAN,$(IOS15PREF)/{Applications,usr/share/pojavlauncher/{instances/default,Library/{Application\ Support,Caches}}}}; \
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
	fakeroot dpkg-deb -b $(OUTPUTDIR)/net.kdt.pojavlauncher.$(1)-rootless_$(VERSION)_iphoneos-arm64

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
	scp -P $(DEVICE_PORT) $(OUTPUTDIR)/net.kdt.pojavlauncher.$(1)_$(VERSION)_$(2).deb root@$(DEVICE_IP):/var/tmp/net.kdt.pojavlauncher.$(1)_$(VERSION)_$(2).deb; \
	ssh root@$(DEVICE_IP) -p $(DEVICE_PORT) -t "dpkg -i /var/tmp/net.kdt.pojavlauncher.$(1)_$(VERSION)_$(2).deb; uicache -p $(3)/Applications/PojavLauncher.app"

# Function to copy + deploy
DEPLOY     = \
	ldid -S$(SOURCEDIR)/entitlements.xml $(WORKINGDIR)/PojavLauncher.app/PojavLauncher; \
	scp -r -P $(DEVICE_PORT) -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" \
		$(WORKINGDIR)/libOSMesaOverride.dylib.framework \
		$(WORKINGDIR)/PojavCore.framework \
		$(WORKINGDIR)/libawt_xawt.dylib \
		$(WORKINGDIR)/PojavLauncher.app/PojavLauncher \
		$(SOURCEDIR)/JavaApp/local_out/launcher.jar \
		root@$(DEVICE_IP):/var/tmp/; \
	ssh root@$(DEVICE_IP) -p $(DEVICE_PORT) -t " \
		mv /var/tmp/libawt_xawt.dylib $(1)/Applications/PojavLauncher.app/Frameworks/libawt_xawt.dylib && \
		rm -rf $(1)/Applications/PojavLauncher.app/Frameworks/libOSMesaOverride.dylib.framework && \
		mv /var/tmp/libOSMesaOverride.dylib.framework $(1)/Applications/PojavLauncher.app/Frameworks/libOSMesaOverride.dylib.framework && \
		rm -rf $(1)/Applications/PojavLauncher.app/Frameworks/PojavCore.framework && \
		mv /var/tmp/PojavCore.framework $(1)/Applications/PojavLauncher.app/Frameworks/PojavCore.framework && \
		mv /var/tmp/PojavLauncher $(1)/Applications/PojavLauncher.app/PojavLauncher && \
		mv /var/tmp/launcher.jar $(1)/Applications/PojavLauncher.app/libs/launcher.jar && \
		cd $(1)/Applications/PojavLauncher.app/Frameworks && \
		ln -sf libawt_xawt.dylib libawt_headless.dylib && killall PojavLauncher && \
		chown -R 501:501 $(1)/Applications/PojavLauncher.app/*"

# Make sure everything is already available for use. Error if they require something
ifeq ($(call HAS_COMMAND,cmake --version),1)
$(error You need to install cmake)
endif

ifeq ($(call HAS_COMMAND,$(BOOTJDK)/javac -version),1)
$(error You need to install JDK 8)
endif

ifeq ($(IOS),0)
ifeq ($(filter 1.8.0,$(shell $(BOOTJDK)/javac -version &> javaver.txt && cat javaver.txt | cut -b 7-11 && rm -rf javaver.txt)),)
$(error You need to install JDK 8)
endif
endif

ifeq ($(call HAS_COMMAND,ldid),1)
$(error You need to install ldid)
endif

ifeq ($(call HAS_COMMAND,fakeroot -v),1)
$(error You need to install fakeroot)
endif

ifeq ($(call HAS_COMMAND,dpkg-deb --version),1)
$(error You need to install dpkg-dev)
endif


# Now for the actual Makefile recipes.
#  all     - runs clean, native, java, extras, and package.
#  check   - Makes sure that all variables are correct.
#  native  - Builds the Objective-C code.
#  java    - Builds the Java code.
#  extras  - Builds the Assets and Storyboard.
#  deb     - Builds the Debian package.
#  ipa     - Builds the application package.
#  install - runs deb + installs to jailbroken device.
#  deploy  - runs native and java + installs to jailbroken device.

all: clean native java extras deb

check:
	@printf '\nDumping all Makefile variables.\n'
	@printf 'DETECTPLAT           - $(DETECTPLAT)\n'
	@printf 'DETECTARCH           - $(DETECTARCH)\n'
	@printf 'SDKPATH              - $(SDKPATH)\n'
	@printf 'BOOTJDK              - $(BOOTJDK)\n'
	@printf 'SOURCEDIR            - $(SOURCEDIR)\n'
	@printf 'WORKINGDIR           - $(WORKINGDIR)\n'
	@printf 'OUTPUTDIR            - $(OUTPUTDIR)\n'
	@printf 'VERSION              - $(VERSION)\n'
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
		-DCONFIG_COMMIT="$(COMMIT)" \
		-DCONFIG_RELEASE=$(RELEASE) \
		..
	@cd $(WORKINGDIR) && cmake --build . --config $(CMAKE_BUILD_TYPE) --target awt_headless awt_xawt libOSMesaOverride.dylib PojavLauncher
	@rm $(WORKINGDIR)/libawt_headless.dylib
	@echo 'Building PojavLauncher $(VERSION) - NATIVES - End'

java:
	@echo 'Building PojavLauncher $(VERSION) - JAVA - Start'
	@cd $(SOURCEDIR)/JavaApp; \
	mkdir -p local_out/classes; \
	$(BOOTJDK)/javac -cp "libs/*:libs_caciocavallo/*" -d local_out/classes $$(find src -type f -name "*.java" -print) -XDignore.symbol.file || exit 1; \
	cd local_out/classes; \
	$(BOOTJDK)/jar -cf ../launcher.jar * || exit 1
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
	@cp -R $(SOURCEDIR)/Natives/resources/* $(WORKINGDIR)/PojavLauncher.app/ || exit 1
	@cp $(WORKINGDIR)/libawt_xawt.dylib $(WORKINGDIR)/PojavLauncher.app/Frameworks/ || exit 1
	@( cd $(WORKINGDIR)/PojavLauncher.app/Frameworks; ln -sf libawt_xawt.dylib libawt_headless.dylib ) || exit 1
	@cp -R $(WORKINGDIR)/libOSMesaOverride.dylib.framework $(WORKINGDIR)/PojavLauncher.app/Frameworks/ || exit 1
	@cp $(SOURCEDIR)/JavaApp/local_out/launcher.jar $(WORKINGDIR)/PojavLauncher.app/libs/launcher.jar || exit 1
	@cp -R $(SOURCEDIR)/JavaApp/libs/* $(WORKINGDIR)/PojavLauncher.app/libs/ || exit 1
	@cp -R $(SOURCEDIR)/JavaApp/libs_caciocavallo/* $(WORKINGDIR)/PojavLauncher.app/libs_caciocavallo/ || exit 1
	$(call DIRCHECK,$(OUTPUTDIR))
	@cp -R $(WORKINGDIR)/PojavLauncher.app $(OUTPUTDIR)
	@if [ '$(RELEASE)' = '1' ]; then \
		$(call PACKAGING,release); \
	else \
		$(call PACKAGING,development); \
	fi
	@echo 'Building PojavLauncher $(VERSION) - DEB - Start'

		
#ipa: native java extras
#	echo 'Building PojavLauncher $(VERSION) - IPA - Start'
#	cd $(OUTPUTDIR); \
	$(call DIRCHECK,$(OUTPUTDIR)/Payload); \
	cp -R $(POJAV_BUNDLE_DIR) $(OUTPUTDIR)/Payload; \
	rm -rf $(OUTPUTDIR)/Payload/PojavLauncher.app/Frameworks/*.dylib; \
	rm -rf $(OUTPUTDIR)/Payload/PojavLauncher.app/jre; \
	cp -R $(POJAV_JRE_DIR) $(OUTPUTDIR)/Payload/PojavLauncher.app/jre; \
	rm $(OUTPUTDIR)/Payload/PojavLauncher.app/jre/jre $(OUTPUTDIR)/Payload/PojavLauncher.app/jre/lib/src.zip $(OUTPUTDIR)/Payload/PojavLauncher.app/jre/lib/tools.jar; \
	cd $(OUTPUTDIR)/Payload/PojavLauncher.app/jre; \
	rm -f lib/libjsig.dylib; \
	cd $(OUTPUTDIR); \
	$(call DIRCHECK,$(OUTPUTDIR)/IPABuilder); \
	mkdir -p $(OUTPUTDIR)/IPABuilder/{OpenJDK/{Frameworks,jre/lib/jli,jre/lib/server},PojavCore/Frameworks}; \
	cd $(OUTPUTDIR)/IPABuilder/OpenJDK/Frameworks; \
	for dylib in $(POJAV_JRE_DYLIBS); do \
	  dylib_name=$$(basename $$dylib); \
	  mkdir -p $${dylib_name}.framework; \
	  cd $${dylib_name}.framework; \
	  cp $(SOURCEDIR)/depends/Info.plist Info.plist; \
	  defaults write "$$PWD/Info.plist" CFBundleExecutable $$dylib_name; \
	  defaults write "$$PWD/Info.plist" CFBundleIdentifier "net.kdt.pojavlauncher.openjdk8_$$dylib_name"; \
	  defaults write "$$PWD/Info.plist" CFBundleName $$dylib_name; \
	  mv $(OUTPUTDIR)/Payload/PojavLauncher.app/jre/$$dylib $$dylib_name; \
	  RPATH_LIST+="-add_rpath @loader_path/../${dylib_name}.framework "; \
	  cd ..; \
	  echo "- (JRE) Finished $$dylib_name"; \
	done; \
	for dylib in $(POJAV_JRE_DYLIBS); do \
	  dylib_name=$$(basename $$dylib); \
	  install_name_tool $$RPATH_LIST $${dylib_name}.framework/$${dylib_name}; \
	done; \
	mv $(OUTPUTDIR)/OpenJDK/Frameworks/* $(OUTPUTDIR)/Payload/PojavLauncher.app/Frameworks; \
	cd $(OUTPUTDIR)/IPABuilder/PojavCore/Frameworks; \
	for dylib in $(POJAV_BUNDLE_DIR); do \
	  dylib_name=$$(basename $$dylib); \
	  mkdir -p $${dylib_name}.framework; \
	  cd $${dylib_name}.framework; \
	  cp $(SOURCEDIR)/depends/Info.plist Info.plist; \
	  defaults write "$$PWD/Info.plist" CFBundleExecutable $$dylib_name; \
	  defaults write "$$PWD/Info.plist" CFBundleIdentifier "net.kdt.pojavlauncher.$dylib_name"; \
	  defaults write "$$PWD/Info.plist" CFBundleName $$dylib_name; \
	  cp $$POJAV_BUNDLE_DIR/Frameworks/$$dylib_name $$dylib_name; \
	  cd ..; \
	  echo "- (PojavCore) Finished $$dylib_name"; \
	done; \
	rm -r $(OUTPUTDIR)/IPABuilder/PojavCore/Frameworks/libawt_headless.dylib.framework; \
	mv $(OUTPUTDIR)/IPABuilder/PojavCore/Frameworks/* Payload/PojavLauncher.app/Frameworks; \
	ldid -Sentitlements.xml Payload/PojavLauncher.app; \
	rm -f *.ipa; \
	zip --symlinks -r net.kdt.pojavlauncher-$(VERSION).ipa Payload*
#	@echo 'Building PojavLauncher $(VERSION) - IPA - End'

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

deploy: deb
	@echo 'Building PojavLauncher $(VERSION) - DEPLOY - End'
	@if [ '$(DEVICE_IP)' != '' ]; then \
		if [ '$(ROOTLESS)' = '1' ]; then \
			$(call DEPLOY,$(IOS15PREF)); \
		else \
			$(call DEPLOY); \
		fi; \
	else \
		echo 'You need to run '\''export DEVICE_IP=<your iOS device IP>'\'' to use make deploy.'; \
		echo 'If you specified a different port for your device to listen for SSH connections, you need to run '\''export DEVICE_PORT=<your port>'\'' as well.'; \
	fi;
	@echo 'Building PojavLauncher $(VERSION) - DEB - End'

dsym: deb
	@echo 'Building PojavLauncher $(VERSION) - DSYM - Start'
	@cd $(OUTPUTDIR) && dsymutil --arch arm64 $(OUTPUTDIR)/PojavLauncher.app/PojavLauncher
	@cp -r $(OUTPUTDIR)/PojavLauncher.app/PojavLauncher.dSYM $(OUTPUTDIR)
	@echo 'Building PojavLauncher $(VERSION) - DSYM - Start'
  
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
	@echo '    make all                            Builds natives, javaapp, extras, and package'
	@echo '    make native                         Builds the native app'
	@echo '    make java                           Builds the Java app'
	@echo '    make deb                            Builds deb of PojavLauncher'
#	@echo '    make ipa                            Builds ipa of PojavLauncher'
	@echo '    make install                        Copy package to local iDevice'
	@echo '    make deploy                         Copy package to local iDevice'
	@echo '    make clean                          Cleans build directories'

.PHONY: all clean native java extras deb ipa install deploy
