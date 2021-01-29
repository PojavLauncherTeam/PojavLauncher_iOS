# This one is only used for local compile on developer iphone, do not execute!

#!/bin/bash
set -e

CFLAGS="-fmessage-length=0 -fdiagnostics-show-note-include-stack -fmacro-backtrace-limit=0 -Wno-trigraphs -fpascal-strings -O3 -Wno-missing-field-initializers -Wno-missing-prototypes -Wno-return-type -Wno-missing-braces -Wparentheses -Wswitch -Wno-unused-function -Wno-unused-label -Wno-unused-parameter -Wno-unused-variable -Wunused-value -Wno-empty-body -Wno-uninitialized -Wno-unknown-pragmas -Wno-shadow -Wno-four-char-constants -Wno-conversion -Wno-constant-conversion -Wno-int-conversion -Wno-bool-conversion -Wno-enum-conversion -Wno-float-conversion -Wno-non-literal-null-conversion -Wno-objc-literal-conversion -Wshorten-64-to-32 -Wpointer-sign -Wno-newline-eof"

clang -Wl,-rpath,/Applications/PojavLauncher.app/Frameworks -fobjc-arc -x objective-c -Fresources/Frameworks -framework UIKit -framework MetalANGLE -Iresources/Frameworks/MetalANGLE.framework/Headers -dynamiclib -isysroot /var/mobile/theos/sdks/iPhoneOS11.2.sdk $CFLAGS -o libpojavexec.dylib log.m AppDelegate.m UILauncher.m SurfaceViewController.m egl_bridge_ios.m egl_bridge.c input_bridge_v3.c utils.c -DGLES_TESTZ -DUSE_EGLZ

ldid -S../entitlements.xml libpojavexec.dylib

cp libpojavexec.dylib /Applications/PojavLauncher.app/Frameworks/libpojavexec.dylib

echo "BUILD SUCCESSFUL"