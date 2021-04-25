#! /usr/bin/env bash

git clone https://github.com/xybp888/iOS-SDKs.git
mv iOS-SDKs/iPhoneOS13.7.sdk iPhoneOS13.7.sdk

sed -i "7s/-isysroot \/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Developer\/SDKs\/iPhoneOS13.7.sdk/-isysroot ..\/iPhoneOS13.7.sdk/" build_natives_clang.sh

chmod +x *.sh

echo "Ready to go!"