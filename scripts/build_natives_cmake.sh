#!/usr/bin/env bash

set -e

# Compile natives
cd Natives
mkdir -p build
cd build
wget https://github.com/leetal/ios-cmake/raw/master/ios.toolchain.cmake
cmake .. -G Xcode \
 -DCMAKE_TOOLCHAIN_FILE=ios.toolchain.cmake \
 -DPLATFORM=OS64 \
 -DENABLE_BITCODE=FALSE \
 -DDEPLOYMENT_TARGET=12.0 \
 -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED="NO" \
 -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO \
 -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY=""
cmake --build . --config Release --target pojavexec PojavLauncher
cd ../..

# Compile storyboard
mkdir -p Natives/build/Release-iphoneos/PojavLauncher.app/Base.lproj
ibtool --compile Natives/build/Release-iphoneos/PojavLauncher.app/Base.lproj/MinecraftSurface.storyboardc Natives/en.lproj/MinecraftSurface.storyboard

# Copy to target app
mkdir -p Natives/build/Release-iphoneos/PojavLauncher.app/Frameworks
cp Natives/build/Release-iphoneos/libpojavexec.dylib Natives/build/Release-iphoneos/PojavLauncher.app/Frameworks/
cp -R Natives/resources/* Natives/build/Release-iphoneos/PojavLauncher.app/
