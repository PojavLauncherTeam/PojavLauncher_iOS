SHELL := /bin/bash
.SHELLFLAGS = -ec

DETECT := $(shell clang -v 2>&1 | grep Target | cut -b 9-60)
ifneq ($(filter arm64-apple-ios%,$(DETECT)),)
	IOS := 1
endif
ifneq ($(filter arm64-apple-darwin%,$(DETECT)),)
	IOS := 0
endif
ifneq ($(filter x86_64-apple-darwin%,$(DETECT)),)
	IOS := 0
endif

. PHONY: all clean native java extras package copy

all: clean native java extras package copy

native:
	@echo 'Starting build task - native application'
	@if [ '$(IOS)' != '1' ]; then \
		cd Natives; \
		mkdir -p build; \
		cd build; \
		wget https://github.com/leetal/ios-cmake/raw/master/ios.toolchain.cmake &> /dev/null; \
		cmake .. -G Xcode -DCMAKE_TOOLCHAIN_FILE=ios.toolchain.cmake -DDEPLOYMENT_TARGET="12.0" -DENABLE_ARC=TRUE -DENABLE_VISIBILITY=FALSE -DPLATFORM=OS64 -DENABLE_BITCODE=FALSE -DENABLE_STRICT_TRY_COMPILE=FALSE -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED="NO" -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY=""; \
		cmake --build . --config Release --target pojavexec PojavLauncher; \
		cd ../..; \
	elif [ '$(IOS)' = '1' ]; then \
		cd Natives; \
		clang -framework UIKit -Wl,-rpath,/Applications/PojavLauncher.app/Frameworks -fobjc-arc -x objective-c -Fresources/Frameworks -Iresources/Frameworks/MetalANGLE.framework/Headers -isysroot /usr/share/SDKs/iPhoneOS.sdk -o PojavLauncher main.c log.m JavaLauncher.c; \
		clang -framework UIKit -framework MetalANGLE -framework CoreGraphics -framework AuthenticationServices \
		  -dynamiclib -Wl,-rpath,/Applications/PojavLauncher.app/Frameworks -fobjc-arc -x objective-c -Fresources/Frameworks -Iresources/Frameworks/MetalANGLE.framework/Headers -isysroot /usr/share/SDKs/iPhoneOS.sdk -o libpojavexec.dylib \
		  log.m \
		  AppDelegate.m \
		  SceneDelegate.m \
		  UILauncher.m \
		  LauncherViewController.m \
		  LauncherPreferencesViewController.m \
		  LoginViewController.m \
		  SurfaceViewController.m \
		  AboutLauncherViewController.m \
		  LauncherFAQViewController.m \
		  egl_bridge_ios.m \
		  ios_uikit_bridge.m \
		  customcontrols/ControlButton.m \
		  egl_bridge.c \
		  input_bridge_v3.c \
		  utils.c \
		  \
		  -DGLES_TESTZ -DUSE_EGLZ; \
		ldid -S../entitlements.xml PojavLauncher; \
		ldid -S../entitlements.xml libpojavexec.dylib; \
	fi
	@echo 'Finished build task - Native'

java:
	@echo 'Starting build task - Java application'
	@if [ '$(IOS)' != '1' ]; then \
		cd JavaApp; \
		chmod +x gradlew; \
		./gradlew clean build; \
		cd ..; \
	elif [ '$(IOS)' = '1' ]; then \
		cd JavaApp; \
		shopt -s globstar; \
		mkdir -p local_out/classes; \
		/usr/lib/jvm/java-16-openjdk/bin/javac -cp "libs/*" -d local_out/classes src/main/java/**/*.java; \
		cd local_out/classes; \
		/usr/lib/jvm/java-16-openjdk/bin/jar -c -f ../launcher.jar *; \
	fi
	@echo 'Finished build task - JavaApp'

extras:
	@echo 'Starting build task - Extras'
	@if [ '$(IOS)' != '1' ]; then \
		mkdir -p Natives/build/Release-iphoneos/PojavLauncher.app/Base.lproj; \
		xcrun actool Natives/Assets.xcassets --compile Natives/resources --platform iphoneos --minimum-deployment-target 12.0 --app-icon AppIcon --output-partial-info-plist /dev/null; \
		ibtool --compile Natives/build/Release-iphoneos/PojavLauncher.app/Base.lproj/MinecraftSurface.storyboardc Natives/en.lproj/MinecraftSurface.storyboard; \
		ibtool --compile Natives/build/Release-iphoneos/PojavLauncher.app/Base.lproj/LaunchScreen.storyboardc Natives/en.lproj/LaunchScreen.storyboard; \
	elif [ '$(IOS)' = '1' ]; then \
		echo 'Due to the required tools not being available, you cannot compile the extras for PojavLauncher with an iOS device.'; \
	fi
	@echo 'Finished build task - Extras'

package:
	@echo 'Starting build task - Packaging'
	@if [ '$(IOS)' != '1' ]; then \
		cp -R Natives/resources/* Natives/build/Release-iphoneos/PojavLauncher.app/; \
		cp Natives/build/Release-iphoneos/libpojavexec.dylib Natives/build/Release-iphoneos/PojavLauncher.app/Frameworks/; \
		mkdir Natives/build/Release-iphoneos/PojavLauncher.app/libs; \
		cp JavaApp/build/libs/PojavLauncher.jar Natives/build/Release-iphoneos/PojavLauncher.app/libs/launcher.jar; \
		cp -R JavaApp/libs/* Natives/build/Release-iphoneos/PojavLauncher.app/libs/; \
		mkdir -p packages/pojavlauncher_iphoneos-arm/{Applications,var/mobile/Documents/minecraft,var/mobile/Documents/.pojavlauncher}; \
		sudo chown 501:501 packages/pojavlauncher_iphoneos-arm/var/mobile/Documents/*; \
		cp -R Natives/build/Release-iphoneos/PojavLauncher.app packages/pojavlauncher_iphoneos-arm/Applications; \
		cp -R DEBIAN packages/pojavlauncher_iphoneos-arm/DEBIAN; \
		ldid -Sentitlements.xml packages/pojavlauncher_iphoneos-arm/Applications/PojavLauncher.app; \
		fakeroot dpkg-deb -b packages/pojavlauncher_iphoneos-arm; \
	elif [ '$(IOS)' = '1' ]; then \
		mkdir -p Natives/build; \
		mkdir -p Natives/build/Release-iphoneos; \
		mkdir -p Natives/build/Release-iphoneos/PojavLauncher.app; \
		mkdir -p Natives/build/Release-iphoneos/PojavLauncher.app/Frameworks; \
		cp -R /Applications/PojavLauncher.app/Base.lproj Natives/build/Release-iphoneos/PojavLauncher.app/Base.lproj; \
		cp -R Natives/PojavLauncher Natives/build/Release-iphoneos/PojavLauncher.app/PojavLauncher; \
		cp -R Natives/Info.plist Natives/build/Release-iphoneos/PojavLauncher.app/Info.plist;\
		cp -R Natives/PkgInfo Natives/build/Release-iphoneos/PojavLauncher.app/PkgInfo; \
		cp -R Natives/libpojavexec.dylib Natives/build/Release-iphoneos/PojavLauncher.app/Frameworks/libpojavexec.dylib; \
		cp -R Natives/resources/* Natives/build/Release-iphoneos/PojavLauncher.app/; \
		cp -R JavaApp/libs Natives/build/Release-iphoneos/PojavLauncher.app/libs; \
		cp JavaApp/local_out/launcher.jar Natives/build/Release-iphoneos/PojavLauncher.app/libs/; \
		mkdir -p packages/pojavlauncher_iphoneos-arm/{Applications,var/mobile/Documents/minecraft,var/mobile/Documents/.pojavlauncher}; \
		sudo chown 501:501 packages/pojavlauncher_iphoneos-arm/var/mobile/Documents/*; \
		cp -R Natives/build/Release-iphoneos/PojavLauncher.app packages/pojavlauncher_iphoneos-arm/Applications; \
		cp -R DEBIAN packages/pojavlauncher_iphoneos-arm/DEBIAN; \
		ldid -Sentitlements.xml packages/pojavlauncher_iphoneos-arm/Applications/PojavLauncher.app; \
		fakeroot dpkg-deb -b packages/pojavlauncher_iphoneos-arm; \
	fi

copy:
	@echo 'The copy task is not yet implemented.'


clean:
	@rm -rf Natives/build
	@rm -rf JavaApp/build
	@rm -rf packages
	@echo 'Build plate cleaned'

help:
	@echo 'Makefile to compile PojavLauncher                                                     '
	@echo '                                                                                      '
	@echo 'Usage:                                                                                '
	@echo '    make                                Makes everything under all                    '
	@echo '    make all                            Builds natives, javaapp, extras, and package  '
	@echo '    make native                         Builds the native app                         '
	@echo '    make java                           Builds the Java app                           '
	@echo '    make package                        Builds deb of PojavLauncher                   '
	@echo '    make copy                           Copy package to local iDevice                 '
	@echo '    make clean                          Cleans build directories                      '

