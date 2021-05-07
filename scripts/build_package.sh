#!/usr/bin/env bash

set -e

mkdir -p packages/pojavlauncher_iphoneos-arm/{Applications,var/mobile/Documents/minecraft,var/mobile/Documents/.pojavlauncher}
sudo chown 501:501 packages/pojavlauncher_iphoneos-arm/var/mobile/Documents/*
cp -R Natives/build/Release-iphoneos/PojavLauncher.app packages/pojavlauncher_iphoneos-arm/Applications
cp -R DEBIAN packages/pojavlauncher_iphoneos-arm/DEBIAN

ldid -Sentitlements.xml packages/pojavlauncher_iphoneos-arm/Applications/PojavLauncher.app

fakeroot dpkg-deb -b packages/pojavlauncher_iphoneos-arm
