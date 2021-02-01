#!/bin/bash

set -e

mkdir -p packages/pojavlauncher_iphoneos-arm/{DEBIAN,Applications,var/mobile/Documents/minecraft}
cp -R Natives/build/Release-iphoneos/PojavLauncher.app packages/pojavlauncher_iphoneos-arm/Applications
cp control packages/pojavlauncher_iphoneos-arm/DEBIAN

ldid -Sentitlements.xml packages/pojavlauncher_iphoneos-arm/Applications/PojavLauncher.app

fakeroot dpkg-deb -b packages/pojavlauncher_iphoneos-arm
