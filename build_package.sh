#!/bin/bash

set -e

mkdir -p packages/pojavlauncher_iphoneos-arm/{DEBIAN,Applications,var/mobile/Documents/minecraft,var/mobile/Documents/.pojavlauncher}
fakeroot chown 501:501 packages/pojavlauncher_iphoneos-arm/var/mobile/Documents/*
cp -R Natives/build/Release-iphoneos/PojavLauncher.app packages/pojavlauncher_iphoneos-arm/Applications
cp control packages/pojavlauncher_iphoneos-arm/DEBIAN

ldid -Sentitlements.xml packages/pojavlauncher_iphoneos-arm/Applications/PojavLauncher.app

fakeroot dpkg-deb -b packages/pojavlauncher_iphoneos-arm
