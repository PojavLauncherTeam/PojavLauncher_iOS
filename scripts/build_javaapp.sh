#!/usr/bin/env bash

set -e

# Compile java app
cd JavaApp
chmod +x gradlew
./gradlew clean build
cd ..

# Copy to target app
mkdir Natives/build/Release-iphoneos/PojavLauncher.app/libs
cp JavaApp/build/libs/PojavLauncher.jar Natives/build/Release-iphoneos/PojavLauncher.app/libs/launcher.jar
cp JavaApp/libs/* Natives/build/Release-iphoneos/PojavLauncher.app/libs/
