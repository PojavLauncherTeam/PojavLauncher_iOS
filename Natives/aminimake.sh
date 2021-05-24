# This one is only used for local compile on developer iphone, do not execute if
# - You don't know what will it does.
# - No SDK and clang installed.

#!/bin/bash
set -e

CFLAGS="-Wl,-rpath,/Applications/PojavLauncher.app/Frameworks -fobjc-arc -x objective-c -Fresources/Frameworks -Iresources/Frameworks/MetalANGLE.framework/Headers -isysroot /var/mobile/theos/sdks/iPhoneOS13.4.sdk"

clang -framework UIKit $CFLAGS -o PojavLauncher main.c log.m JavaLauncher.c
clang -framework UIKit -framework MetalANGLE -framework CoreGraphics -framework AuthenticationServices \
  -dynamiclib $CFLAGS -o libpojavexec.dylib \
  log.m \
  AppDelegate.m \
  SceneDelegate.m \
  UILauncher.m \
  LauncherViewController.m \
  LauncherPreferencesViewController.m \
  LoginViewController.m \
  SurfaceViewController.m \
  egl_bridge_ios.m \
  ios_uikit_bridge.m \
  customcontrols/ControlButton.m \
  egl_bridge.c \
  input_bridge_v3.c \
  utils.c \
\
  -DGLES_TESTZ -DUSE_EGLZ 
# -Wl,-undefined,dynamic_lookup

ldid -S../entitlements.xml PojavLauncher
ldid -S../entitlements.xml libpojavexec.dylib

cp PojavLauncher /Applications/PojavLauncher.app/PojavLauncher
cp libpojavexec.dylib /Applications/PojavLauncher.app/Frameworks/libpojavexec.dylib

echo "BUILD SUCCESSFUL"
