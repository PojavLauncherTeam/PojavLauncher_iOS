#!/usr/bin/env bash

set -e

mkdir -p packages/pojavlauncher_iphoneos-arm/{Applications,var/mobile/Documents/minecraft,var/mobile/Documents/.pojavlauncher}
sudo chown 501:501 packages/pojavlauncher_iphoneos-arm/var/mobile/Documents/*
cp -R Natives/build/Release-iphoneos/PojavLauncher.app packages/pojavlauncher_iphoneos-arm/Applications
cp -R DEBIAN packages/pojavlauncher_iphoneos-arm/DEBIAN

ldid -Sentitlements.xml packages/pojavlauncher_iphoneos-arm/Applications/PojavLauncher.app

fakeroot dpkg-deb -b packages/pojavlauncher_iphoneos-arm

if [[ "$DEVICE_IP" != "" ]];
then
      if [[ "$DEVICE_PORT" != "" ]];
      then
            scp -P $DEVICE_PORT packages/pojavlauncher_iphoneos-arm.deb root@$DEVICE_IP:/var/tmp/pojavlauncher_iphoneos-arm.deb
            ssh root@$DEVICE_IP -p $DEVICE_PORT -t "apt remove pojavlauncher; apt remove pojavlauncher-dev; dpkg -i /var/tmp/pojavlauncher_iphoneos-arm.deb; uicache -p /Applications/PojavLauncher.app"
      else
            scp packages/pojavlauncher_iphoneos-arm.deb root@$DEVICE_IP:/var/tmp/pojavlauncher_iphoneos-arm.deb
            ssh root@$DEVICE_IP -t "apt remove pojavlauncher; apt remove pojavlauncher-dev; dpkg -i /var/tmp/pojavlauncher_iphoneos-arm.deb; uicache -p /Applications/PojavLauncher.app"
       fi
else
      echo "Device address not set, not installing."
fi
