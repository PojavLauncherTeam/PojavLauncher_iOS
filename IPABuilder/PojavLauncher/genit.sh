#!/bin/bash
set -e

cd "$POJAV_BUNDLE_DIR/Frameworks"
all_dylibs=$(echo *.dylib)

cd "$OLDPWD"
rm -rf Frameworks
mkdir Frameworks
cd Frameworks

for dylib in $all_dylibs; do
  dylib_name=$(basename $dylib)
  mkdir -p ${dylib_name}.framework
  cd ${dylib_name}.framework
  cp ../../template/Info.plist Info.plist
  defaults write "$PWD/Info.plist" CFBundleExecutable $dylib_name
  defaults write "$PWD/Info.plist" CFBundleIdentifier "net.kdt.pojavlauncher.$dylib_name"
  defaults write "$PWD/Info.plist" CFBundleName $dylib_name
  # plutil -convert xml1 ${dylib_name}.Framework/Info.plist
  cp $POJAV_BUNDLE_DIR/Frameworks/$dylib_name $dylib_name
  cd ..
  echo "- Finished $dylib_name"
done
