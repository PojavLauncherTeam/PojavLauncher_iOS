SHELL := /bin/bash
.SHELLFLAGS = -ec

DETECT := $(shell clang -v 2>&1 | grep Target | cut -b 9-60)
ifneq ($(filter arm64-apple-ios%,$(DETECT)),)
	IOS     := 1
	SDKPATH := /usr/share/SDKs/iPhoneOS.sdk
endif
ifneq ($(filter arm64-apple-darwin%,$(DETECT)),)
	IOS     := 0
	SDKPATH := $(shell xcrun --sdk iphoneos --show-sdk-path)
endif
ifneq ($(filter x86_64-apple-darwin%,$(DETECT)),)
	IOS     := 0
	SDKPATH := $(shell xcrun --sdk iphoneos --show-sdk-path)
endif

. PHONY: all clean native java extras package install

all: clean native java extras package install

native:
	@echo 'Starting build task - native application'
	mkdir -p Natives/build
	cd Natives/build && cmake . \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_SYSTEM_PROCESSOR=aarch64 \
		-DCMAKE_C_FLAGS="-arch arm64 -isysroot $(SDKPATH) -miphoneos-version-min=12.0" \
		..
	cd Natives/build && cmake --build . --config Release --target pojavexec PojavLauncher || exit 1
	@echo 'Finished build task - native application'

java:
	@echo 'Starting build task - java application'
	@if [ '$(IOS)' = '0' ]; then \
		cd JavaApp; \
		chmod +x gradlew; \
		./gradlew clean build || exit 1; \
		cd ..; \
	elif [ '$(IOS)' = '1' ]; then \
		cd JavaApp; \
		shopt -s globstar; \
		mkdir -p local_out/classes; \
		/usr/lib/jvm/java-16-openjdk/bin/javac -cp "libs/*" -d local_out/classes src/main/java/**/*.java &> /dev/null || exit 1; \
		cd local_out/classes; \
		/usr/lib/jvm/java-16-openjdk/bin/jar -c -f ../launcher.jar * || exit 1; \
	fi
	@echo 'Finished build task - java application'

extras:
	@echo 'Starting build task - extraneous files'
	@if [ '$(IOS)' = '0' ]; then \
		mkdir -p Natives/build/Release-iphoneos/PojavLauncher.app/Base.lproj; \
		xcrun actool Natives/Assets.xcassets --compile Natives/resources --platform iphoneos --minimum-deployment-target 12.0 --app-icon AppIcon --output-partial-info-plist /dev/null || exit 1; \
		ibtool --compile Natives/build/Release-iphoneos/PojavLauncher.app/Base.lproj/MinecraftSurface.storyboardc Natives/en.lproj/MinecraftSurface.storyboard || exit 1; \
		ibtool --compile Natives/build/Release-iphoneos/PojavLauncher.app/Base.lproj/LaunchScreen.storyboardc Natives/en.lproj/LaunchScreen.storyboard || exit 1; \
	elif [ '$(IOS)' = '1' ]; then \
		echo 'Due to the required tools not being available, you cannot compile the extras for PojavLauncher with an iOS device.'; \
	fi
	@echo 'Finished build task - extraneous files'

package:
	@echo 'Starting build task - package for external devices'
	@if [ '$(IOS)' = '0' ]; then \
		cp -R Natives/resources/* Natives/build/Release-iphoneos/PojavLauncher.app/ || exit 1; \
		cp Natives/build/Release-iphoneos/libpojavexec.dylib Natives/build/Release-iphoneos/PojavLauncher.app/Frameworks/ || exit 1; \
		mkdir Natives/build/Release-iphoneos/PojavLauncher.app/libs; \
		cp JavaApp/build/libs/PojavLauncher.jar Natives/build/Release-iphoneos/PojavLauncher.app/libs/launcher.jar || exit 1; \
		cp -R JavaApp/libs/* Natives/build/Release-iphoneos/PojavLauncher.app/libs/ || exit 1; \
		mkdir -p packages/pojavlauncher_iphoneos-arm/{Applications,var/mobile/Documents/minecraft,var/mobile/Documents/.pojavlauncher}; \
		sudo chown 501:501 packages/pojavlauncher_iphoneos-arm/var/mobile/Documents/* || exit 1; \
		cp -R Natives/build/Release-iphoneos/PojavLauncher.app packages/pojavlauncher_iphoneos-arm/Applications; \
		cp -R DEBIAN packages/pojavlauncher_iphoneos-arm/DEBIAN; \
		ldid -Sentitlements.xml packages/pojavlauncher_iphoneos-arm/Applications/PojavLauncher.app || exit 1; \
		fakeroot dpkg-deb -b packages/pojavlauncher_iphoneos-arm || exit 1; \
	elif [ '$(IOS)' = '1' ]; then \
		mkdir -p Natives/build; \
		mkdir -p Natives/build/Release-iphoneos; \
		mkdir -p Natives/build/Release-iphoneos/PojavLauncher.app; \
		mkdir -p Natives/build/Release-iphoneos/PojavLauncher.app/Frameworks; \
		mkdir -p Natives/build/Release-iphoneos/PojavLauncher.app/Base.lproj; \
		cp -R Natives/en.lproj/*.storyboardc Natives/build/Release-iphoneos/PojavLauncher.app/Base.lproj/ || exit 1; \
		cp -R Natives/PojavLauncher Natives/build/Release-iphoneos/PojavLauncher.app/PojavLauncher || exit 1; \
		cp -R Natives/Info.plist Natives/build/Release-iphoneos/PojavLauncher.app/Info.plist || exit 1;\
		cp -R Natives/PkgInfo Natives/build/Release-iphoneos/PojavLauncher.app/PkgInfo || exit 1; \
		cp -R Natives/libpojavexec.dylib Natives/build/Release-iphoneos/PojavLauncher.app/Frameworks/libpojavexec.dylib || exit 1; \
		cp -R Natives/resources/* Natives/build/Release-iphoneos/PojavLauncher.app/ || exit 1; \
		cp -R JavaApp/libs Natives/build/Release-iphoneos/PojavLauncher.app/libs || exit 1; \
		cp JavaApp/local_out/launcher.jar Natives/build/Release-iphoneos/PojavLauncher.app/libs/ || exit 1; \
		mkdir -p packages/pojavlauncher_iphoneos-arm/{Applications,var/mobile/Documents/minecraft,var/mobile/Documents/.pojavlauncher}; \
		sudo chown 501:501 packages/pojavlauncher_iphoneos-arm/var/mobile/Documents/*; \
		cp -R Natives/build/Release-iphoneos/PojavLauncher.app packages/pojavlauncher_iphoneos-arm/Applications; \
		cp -R DEBIAN packages/pojavlauncher_iphoneos-arm/DEBIAN; \
		ldid -Sentitlements.xml packages/pojavlauncher_iphoneos-arm/Applications/PojavLauncher.app || exit 1; \
		fakeroot dpkg-deb -b packages/pojavlauncher_iphoneos-arm &> /dev/null || exit 1; \
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
			if [ '$(DEVICE_PORT)' != '' ]; then \
				scp -P $(DEVICE_PORT) Natives/libpojavexec.dylib root@$(DEVICE_IP):/Applications/PojavLauncher.app/Frameworks/libpojavexec.dylib || exit 1; \
				ssh root@$(DEVICE_IP) -p $(DEVICE_PORT) -t "killall PojavLauncher"; \
			else \
				scp Natives/libpojavexec.dylib root@$(DEVICE_IP):/Applications/PojavLauncher.app/Frameworks/libpojavexec.dylib || exit 1; \
				ssh root@$(DEVICE_IP) -t "killall PojavLauncher"; \
			fi; \
		else \
			echo 'You need to run '\''export DEVICE_IP=<your iOS device IP>'\'' to use make deploy.'; \
			echo 'If you specified a different port for your device to listen for SSH connections, you need to run '\''export DEVICE_PORT=<your port>'\'' as well.'; \
		fi; \
	elif [ '$(IOS)' = '1' ]; then \
	    sudo cp JavaApp/local_out/launcher.jar /Applications/PojavLauncher.app/libs/launcher.jar; \
		sudo cp Natives/PojavLauncher /Applications/PojavLauncher.app/PojavLauncher; \
		sudo cp Natives/libpojavexec.dylib /Applications/PojavLauncher.app/Frameworks/libpojavexec.dylib; \
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

