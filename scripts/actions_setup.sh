#! /usr/bin/env bash

git clone https://github.com/xybp888/iOS-SDKs.git
mv iOS-SDKs/iPhoneOS12.1.2.sdk iPhoneOS12.1.2.sdk

sed -i "" "7s/-isysroot \/Applications\/Xcode.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform\/Developer\/SDKs\/iPhoneOS13.7.sdk/-isysroot ..\/iPhoneOS12.1.2.sdk/" scripts/build_natives_clang.sh

chmod +x scripts/*.sh

echo "Ready to go!"
