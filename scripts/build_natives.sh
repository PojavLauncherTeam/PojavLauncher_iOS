#!/usr/bin/env bash

set -e

rm -rf Natives/build

# Compile natives
cd Natives
mkdir -p build
cd build
wget https://github.com/leetal/ios-cmake/raw/master/ios.toolchain.cmake
cmake .. -G Xcode -DCMAKE_TOOLCHAIN_FILE=ios.toolchain.cmake -DDEPLOYMENT_TARGET="12.0" -DENABLE_ARC=TRUE -DENABLE_VISIBILITY=FALSE -DPLATFORM=OS64 -DENABLE_BITCODE=FALSE -DENABLE_STRICT_TRY_COMPILE=FALSE -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED="NO" -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY=""
cmake --build . --config Release --target pojavexec PojavLauncher
cd ../..

# Compile storyboard
mkdir -p Natives/build/Release-iphoneos/PojavLauncher.app/Base.lproj
ibtool --compile Natives/build/Release-iphoneos/PojavLauncher.app/Base.lproj/MinecraftSurface.storyboardc Natives/en.lproj/MinecraftSurface.storyboard

# Copy to target app
mkdir -p Natives/build/Release-iphoneos/PojavLauncher.app/Frameworks
cp Natives/build/Release-iphoneos/libpojavexec.dylib Natives/build/Release-iphoneos/PojavLauncher.app/Frameworks/
cp -R Natives/resources/* Natives/build/Release-iphoneos/PojavLauncher.app/
