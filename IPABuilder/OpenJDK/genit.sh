#!/bin/bash
set -e

RPATH_LIST=""
NEW_JAVA_HOME=jre8

# JAVA_HOME=/Applications/PojavLauncher.app/Frameworks
# NEW_JAVA_HOME=Frameworks

cd ../Payload/PojavLauncher.app/jre

rm -f lib/libjsig.dylib

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
  RPATH_LIST+="-add_rpath @loader_path/../${dylib_name}.framework "
  cd ..
  echo "- Finished $dylib_name"
done

echo "Add RPATH to libraries"

for dylib in $all_dylibs; do
  dylib_name=$(basename $dylib)
  install_name_tool $RPATH_LIST ${dylib_name}.framework/${dylib_name}
done
