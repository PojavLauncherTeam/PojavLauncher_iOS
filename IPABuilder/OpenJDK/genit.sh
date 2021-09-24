#!/bin/bash
set -e

NEW_JAVA_HOME=jre8

# JAVA_HOME=/Applications/PojavLauncher.app/Frameworks
# NEW_JAVA_HOME=Frameworks

cd ../Payload/PojavLauncher.app/jre
all_dylibs=$(find . -name "*.dylib")

cd "$OLDPWD"
rm -rf Frameworks jre
mkdir -p Frameworks jre/lib/jli jre/lib/server
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
  mv ../../../Payload/PojavLauncher.app/jre/$dylib $dylib_name
  cd ..
  echo "- Finished $dylib_name"
done
