#!/bin/bash
set -e

git clone https://github.com/davidandreoletti/libegl
cd libegl
cd proj && make build-iphoneos-release
cd ..
cp prefix/libArm64.a/ ../Natives/libEGL.a
