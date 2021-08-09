SHELL := /bin/bash
.SHELLFLAGS = -ec


DETECT  := $(shell clang -v 2>&1 | grep Target | cut -b 9-60)

# The below are going to be used for the AboutLauncherViewController.m file's version.
# Formatting will be similar to one of the below:
# version 1.3 (dev - fdc492b) on iPhone9,1 running 14.6
# version 1.3 on iPhone9,1 running 14.6
VERSION := $(shell cat DEBIAN/control | grep Version | cut -b 9-60)
COMMIT  := $(shell git log --oneline | sed '2,10000000d' | cut -b 1-7)
ifndef RELEASE
RELEASE := 0
endif
ifeq (1,$(RELEASE))
CMAKE_BUILD_TYPE := RelWithDebInfo
else
CMAKE_BUILD_TYPE := Debug
endif

# Distinguish iOS from macOS
ifneq ($(filter arm64-apple-ios%,$(DETECT)),)
IOS         := 1
SDKPATH     := /usr/share/SDKs/iPhoneOS.sdk
SED			:= sed
endif
ifneq ($(filter aarch64-apple-darwin%,$(DETECT)),)
IOS         := 0
SDKPATH     := $(shell xcrun --sdk iphoneos --show-sdk-path)
SED			:= gsed
endif
ifneq ($(filter x86_64-apple-darwin%,$(DETECT)),)
IOS         := 0
SDKPATH     := $(shell xcrun --sdk iphoneos --show-sdk-path)
SED			:= gsed
endif

JAVAFILES   := $(shell cd JavaApp; find src -type f -name "*.java" -print)

# Make sure everything is already available for use. Warn the user if they require
# something.
ifneq ($(filter 1,$(IOS)),)
	ifeq ($(filter 1,$(shell sed --version 2>&1 /dev/null && echo 1)),)
		$(error You need to install sed)
	endif
    ifeq ($(filter 1,$(shell cmake --version 2>&1 /dev/null && echo 1)),)
        $(error You need to install cmake)
    endif
    ifeq ($(filter 1,$(shell /usr/lib/jvm/java-8-openjdk/bin/javac -version &> /dev/null && echo 1)),)
        $(warning You are not using JDK 8 to compile.)
        ifeq ($(filter 1,$(shell /usr/lib/jvm/java-16-openjdk/bin/javac -version &> /dev/null && echo 1)),)
            $(error You need to install openjdk-8-jdk or openjdk-16-jdk)
        else
            JDK := /usr/lib/jvm/java-16-openjdk/bin
        endif
    else
        JDK := /usr/lib/jvm/java-8-openjdk/bin
    endif
    ifeq ($(filter 1,$(shell ldid &> /dev/null && echo 1)),)
        $(error You need to install ldid)
    endif
    ifeq ($(filter 1,$(shell fakeroot -v 2>&1 /dev/null && echo 1)),)
        $(error You need to install fakeroot)
    endif
    ifeq ($(filter 1,$(shell dpkg-deb --version 2>&1 /dev/null && echo 1)),)
        $(error You need to install dpkg-dev)
    endif
else ifneq ($(filter 0,$(IOS)),)
	ifeq ($(filter 1,$(shell gsed --version 2>&1 /dev/null && echo 1)),)
		$(error You need to install gsed)
	endif
    ifeq ($(filter 1,$(shell cmake --version 2>&1 /dev/null && echo 1)),)
            $(error You need to install cmake)
    endif
    ifeq ($(filter 1.8.0,$(shell javac -version &> javaver.txt && cat javaver.txt | cut -b 7-11 && rm -rf javaver.txt)),)
        $(warning You are not using JDK 8 to compile.)
        ifeq ($(filter 1,$(shell javac -version &> /dev/null && echo 1)),)
            $(error You need to install a JDK)
        else
            JDK := /usr/bin
        endif
    else
        JDK := /usr/bin
    endif
    ifeq ($(filter 1,$(shell ldid &> /dev/null && echo 1)),)
            $(error You need to install ldid)
    endif
    ifeq ($(filter 1,$(shell fakeroot -v 2>&1 /dev/null && echo 1)),)
        	ifneq ($(filter x86_64,$(shell uname -p)),)
                $(error You need to install fakeroot. It can only be found on Procursus for Apple Silicon)
            else
                $(error You need to install fakeroot)
        endif
    endif
    ifeq ($(filter 1,$(shell dpkg-deb --version 2>&1 /dev/null && echo 1)),)
        $(error You need to install the dpkg developer tools)
    endif
endif


all: clean native java extras package

native:
	@echo 'Starting build task - native application'
	@mkdir -p Natives/build
	@cd Natives/build && cmake . \
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
	@cd Natives/build && cmake --build . --config $(CMAKE_BUILD_TYPE) --target awt_headless awt_xawt pojavexec PojavLauncher
	@rm Natives/build/libawt_headless.dylib
	@echo 'Finished build task - native application'

java:
	@echo 'Starting build task - java application'
	@cd JavaApp; \
	mkdir -p local_out/classes; \
	$(JDK)/javac -cp "libs/*:libs_caciocavallo/*" -d local_out/classes $(JAVAFILES) || exit 1; \
	cd local_out/classes; \
	$(JDK)/jar -cf ../launcher.jar * || exit 1; \
	echo 'Finished build task - java application'

extras:
	@echo 'Starting build task - extraneous files'
	@if [ '$(IOS)' = '0' ]; then \
		mkdir -p Natives/build/PojavLauncher.app/Base.lproj; \
		xcrun actool Natives/Assets.xcassets --compile Natives/resources --platform iphoneos --minimum-deployment-target 12.0 --app-icon AppIcon --output-partial-info-plist /dev/null || exit 1; \
		ibtool --compile Natives/build/PojavLauncher.app/Base.lproj/LaunchScreen.storyboardc Natives/en.lproj/LaunchScreen.storyboard || exit 1; \
	elif [ '$(IOS)' = '1' ]; then \
		echo 'Due to the required tools not being available, you cannot compile the extras for PojavLauncher with an iOS device.'; \
	fi
	@echo 'Finished build task - extraneous files'

package:
	@echo 'Starting build task - package for external devices'
	@if [ '$(IOS)' = '0' ]; then \
		cp -R Natives/resources/* Natives/build/PojavLauncher.app/ || exit 1; \
		cp Natives/build/libawt_xawt.dylib Natives/build/PojavLauncher.app/Frameworks/ || exit 1; \
		( cd Natives/build/PojavLauncher.app/Frameworks; ln -sf libawt_xawt.dylib libawt_headless.dylib ) || exit 1; \
		cp Natives/build/libpojavexec.dylib Natives/build/PojavLauncher.app/Frameworks/ || exit 1; \
		mkdir Natives/build/PojavLauncher.app/{libs,libs_caciocavallo}; \
		cp JavaApp/local_out/launcher.jar Natives/build/PojavLauncher.app/libs/launcher.jar || exit 1; \
		cp -R JavaApp/libs/* Natives/build/PojavLauncher.app/libs/ || exit 1; \
		cp -R JavaApp/libs_caciocavallo/* Natives/build/PojavLauncher.app/libs_caciocavallo/ || exit 1; \
		mkdir -p packages/pojavlauncher_iphoneos-arm/{Applications,var/mobile/Documents/minecraft,var/mobile/Documents/.pojavlauncher}; \
		sudo chown 501:501 packages/pojavlauncher_iphoneos-arm/var/mobile/Documents/* || exit 1; \
		cp -R Natives/build/PojavLauncher.app packages/pojavlauncher_iphoneos-arm/Applications; \
		cp -R DEBIAN packages/pojavlauncher_iphoneos-arm/DEBIAN; \
		ldid -Sentitlements.xml packages/pojavlauncher_iphoneos-arm/Applications/PojavLauncher.app || exit 1; \
		fakeroot dpkg-deb -b packages/pojavlauncher_iphoneos-arm || exit 1; \
	elif [ '$(IOS)' = '1' ]; then \
		mkdir -p Natives/build/PojavLauncher.app/{Frameworks,Base.lproj}; \
		cp -R Natives/en.lproj/*.storyboardc Natives/build/PojavLauncher.app/Base.lproj/ || exit 1; \
		cp -R Natives/Info.plist Natives/build/PojavLauncher.app/Info.plist || exit 1;\
		cp -R Natives/PkgInfo Natives/build/PojavLauncher.app/PkgInfo || exit 1; \
		cp Natives/build/libawt_xawt.dylib Natives/build/PojavLauncher.app/Frameworks/ || exit 1; \
		( cd Natives/build/PojavLauncher.app/Frameworks; ln -sf libawt_xawt.dylib libawt_headless.dylib ) || exit 1; \
		cp Natives/build/libpojavexec.dylib Natives/build/PojavLauncher.app/Frameworks/ || exit 1; \
		cp -R Natives/resources/* Natives/build/PojavLauncher.app/ || exit 1; \
		cp -R JavaApp/libs Natives/build/PojavLauncher.app/libs || exit 1; \
		cp -R JavaApp/libs_caciocavallo Natives/build/PojavLauncher.app/libs_caciocavallo || exit 1; \
		cp JavaApp/local_out/launcher.jar Natives/build/PojavLauncher.app/libs/ || exit 1; \
		mkdir -p packages/pojavlauncher_iphoneos-arm/{Applications,var/mobile/Documents/minecraft,var/mobile/Documents/.pojavlauncher}; \
		sudo chown 501:501 packages/pojavlauncher_iphoneos-arm/var/mobile/Documents/* || exit 1; \
		cp -R Natives/build/PojavLauncher.app packages/pojavlauncher_iphoneos-arm/Applications; \
		cp -R DEBIAN packages/pojavlauncher_iphoneos-arm/DEBIAN; \
		ldid -Sentitlements.xml packages/pojavlauncher_iphoneos-arm/Applications/PojavLauncher.app || exit 1; \
		fakeroot dpkg-deb -b packages/pojavlauncher_iphoneos-arm || exit 1; \
	fi
	@echo 'Finished build task - package for external devices'

install:
	@echo 'Starting build task - installing to local device'
	@echo 'Please note that this may not work properly. If it doesn'\''t work for you, you can manually extract the .deb in /var/tmp/pojavlauncher_iphoneos-arm.deb with dpkg or Filza.'
	@if [ '$(IOS)' = '0' ]; then \
		if [ '$(DEVICE_IP)' != '' ]; then \
			if [ '$(DEVICE_PORT)' != '' ]; then \
				scp -P $(DEVICE_PORT) packages/pojavlauncher_iphoneos-arm.deb root@$(DEVICE_IP):/var/tmp/pojavlauncher_iphoneos-arm.deb; \
				ssh root@$(DEVICE_IP) -p $(DEVICE_PORT) -t "apt remove pojavlauncher; apt remove pojavlauncher-dev; dpkg -i /var/tmp/pojavlauncher_iphoneos-arm.deb; uicache -p /Applications/PojavLauncher.app"; \
			else \
				scp packages/pojavlauncher_iphoneos-arm.deb root@$(DEVICE_IP):/var/tmp/pojavlauncher_iphoneos-arm.deb; \
				ssh root@$(DEVICE_IP) -t "apt remove pojavlauncher; apt remove pojavlauncher-dev; dpkg -i /var/tmp/pojavlauncher_iphoneos-arm.deb; uicache -p /Applications/PojavLauncher.app"; \
			fi; \
		else \
			echo 'You need to run '\''export DEVICE_IP=<your iOS device IP>'\'' to use make install.'; \
			echo 'If you specified a different port for your device to listen for SSH connections, you need to run '\''export DEVICE_PORT=<your port>'\'' as well.'; \
		fi; \
	elif [ '$(IOS)' = '1' ]; then \
		sudo apt remove pojavlauncher -y; \
		sudo apt remove pojavlauncher-dev -y; \
		sudo cp packages/pojavlauncher_iphoneos-arm.deb /var/tmp/pojavlauncher_iphoneos-arm.deb; \
		sudo dpkg -i /var/tmp/pojavlauncher_iphoneos-arm.deb; \
		uicache -p /Applications/PojavLauncher.app; \
	fi

deploy:
	@echo 'Starting build task - deploy to local device'
	@if [ '$(IOS)' = '0' ]; then \
		if [ '$(DEVICE_IP)' != '' ]; then \
			ldid -Sentitlements.xml Natives/build/PojavLauncher.app/PojavLauncher; \
			if [ '$(DEVICE_PORT)' != '' ]; then \
				scp -P $(DEVICE_PORT) -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" Natives/build/libpojavexec.dylib \
				    Natives/build/libawt_xawt.dylib \
					Natives/build/PojavLauncher.app/PojavLauncher \
					JavaApp/local_out/launcher.jar \
					root@$(DEVICE_IP):/var/tmp; \
				ssh root@$(DEVICE_IP) -p $(DEVICE_PORT) -t "mv /var/tmp/libawt_xawt.dylib /Applications/PojavLauncher.app/Frameworks/libawt_xawt.dylib && mv /var/tmp/libpojavexec.dylib /Applications/PojavLauncher.app/Frameworks/libpojavexec.dylib && mv /var/tmp/PojavLauncher /Applications/PojavLauncher.app/PojavLauncher && mv /var/tmp/launcher.jar /Applications/PojavLauncher.app/libs/launcher.jar && cd /Applications/PojavLauncher.app/Frameworks && ln -sf libawt_xawt.dylib libawt_headless.dylib && killall PojavLauncher"; \
			else \
				scp -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" Natives/build/libpojavexec.dylib \
				    Natives/build/libawt_xawt.dylib \
					Natives/build/PojavLauncher.app/PojavLauncher \
					JavaApp/local_out/launcher.jar \
					root@$(DEVICE_IP):/var/tmp; \
				ssh root@$(DEVICE_IP) -t "mv /var/tmp/libawt_xawt.dylib /Applications/PojavLauncher.app/Frameworks/libawt_xawt.dylib && mv /var/tmp/libpojavexec.dylib /Applications/PojavLauncher.app/Frameworks/libpojavexec.dylib && mv /var/tmp/PojavLauncher /Applications/PojavLauncher.app/PojavLauncher && mv /var/tmp/launcher.jar /Applications/PojavLauncher.app/libs/launcher.jar && cd /Applications/PojavLauncher.app/Frameworks && ln -sf libawt_xawt.dylib libawt_headless.dylib && killall PojavLauncher"; \
			fi; \
		else \
			echo 'You need to run '\''export DEVICE_IP=<your iOS device IP>'\'' to use make deploy.'; \
			echo 'If you specified a different port for your device to listen for SSH connections, you need to run '\''export DEVICE_PORT=<your port>'\'' as well.'; \
		fi; \
	elif [ '$(IOS)' = '1' ]; then \
		sudo ldid -Sentitlements.xml Natives/build/PojavLauncher.app/PojavLauncher; \
		sudo cp JavaApp/local_out/launcher.jar /Applications/PojavLauncher.app/libs/launcher.jar; \
		sudo cp Natives/build/PojavLauncher.app/PojavLauncher /Applications/PojavLauncher.app/PojavLauncher; \
		sudo cp Natives/build/libawt_xawt.dylib /Applications/PojavLauncher.app/Frameworks/; \
		sudo cp Natives/build/libpojavexec.dylib /Applications/PojavLauncher.app/Frameworks/; \
		cd /Applications/PojavLauncher.app/Frameworks; \
		sudo ln -sf libawt_xawt.dylib libawt_headless.dylib; \
		sudo killall PojavLauncher; \
	fi
	@echo 'Finished build task - deploy to local device'
		
clean:
	@echo 'Starting build task - cleaning build workspace'
	@rm -rf Natives/build
	@rm -rf JavaApp/build
	@rm -rf packages
	@echo 'Finished build task - cleaned build workspace'

help:
	@echo 'Makefile to compile PojavLauncher                                                     '
	@echo '                                                                                      '
	@echo 'Usage:                                                                                '
	@echo '    make                                Makes everything under all                    '
	@echo '    make all                            Builds natives, javaapp, extras, and package  '
	@echo '    make native                         Builds the native app                         '
	@echo '    make java                           Builds the Java app                           '
	@echo '    make package                        Builds deb of PojavLauncher                   '
	@echo '    make install                        Copy package to local iDevice                 '
	@echo '    make deploy                         Copy package to local iDevice                 '
	@echo '    make clean                          Cleans build directories                      '

. PHONY: all clean native java extras package install deploy
