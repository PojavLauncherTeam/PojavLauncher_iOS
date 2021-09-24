#!/bin/bash
set -e

rm -rf Payload*

# /usr/lib/jvm/java-8-openjdk

echo "Copy"
mkdir -p Payload
cp -R $POJAV_BUNDLE_DIR Payload/
rm -rf Payload/PojavLauncher.app/Frameworks/*.dylib

echo "Copy OpenJDK"
rm -rf Payload/PojavLauncher.app/jre
cp -R $POJAV_JRE_DIR Payload/PojavLauncher.app/jre
rm Payload/PojavLauncher.app/jre/jre Payload/PojavLauncher.app/jre/lib/src.zip Payload/PojavLauncher.app/jre/lib/tools.jar || echo "Remove exited with code $?"

echo "Generate OpenJDK dylibs"
( cd OpenJDK && bash genit.sh )
mv OpenJDK/Frameworks/* Payload/PojavLauncher.app/Frameworks

echo "Generate PojavLauncher dylibs"
( cd PojavLauncher && bash genit.sh )
rm -r PojavLauncher/Frameworks/libawt_headless.dylib.framework
mv PojavLauncher/Frameworks/* Payload/PojavLauncher.app/Frameworks

# Fix libOSMesaOverride.dylib
# cd Payload/PojavLauncher.app/Frameworks/libOSMesaOverride.dylib.framework
# cp ../../../../PojavLauncher/template/Info.plist Info.plist
# defaults write "$PWD/Info.plist" CFBundleExecutable libOSMesaOverride.dylib
# defaults write "$PWD/Info.plist" CFBundleIdentifier "net.kdt.pojavlauncher.libOSMesaOverride.dylib"
# defaults write "$PWD/Info.plist" CFBundleName libOSMesaOverride.dylib
# cd ../../../..

echo "Sign"
ldid -Sentitlements.xml Payload/PojavLauncher.app

echo "Create IPA"
rm -f Payload.ipa
zip --symlinks -r Payload.ipa Payload

echo "Done"