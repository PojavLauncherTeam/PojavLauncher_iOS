cmake_minimum_required(VERSION 3.6)
project(PojavLauncher)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fcommon -fobjc-arc -ObjC -I${CMAKE_CURRENT_LIST_DIR}/resources/Frameworks/MetalANGLE.framework/Headers")

add_executable(PojavLauncher main.c log.m JavaLauncher.c)
target_link_libraries(PojavLauncher
    "-framework UIKit"
)
set_target_properties(PojavLauncher PROPERTIES
  MACOSX_BUNDLE TRUE
  MACOSX_FRAMEWORK_IDENTIFIER org.cmake.ExecutableTarget
  MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_LIST_DIR}/Info.plist")

add_library(pojavexec SHARED log.m AppDelegate.m SceneDelegate.m UILauncher.m LauncherViewController.m LauncherPreferencesViewController.m LauncherFAQViewController.m LoginViewController.m SurfaceViewController.m UpdateHistoryViewController.m AboutLauncherViewController.m egl_bridge_ios.m ios_uikit_bridge.m customcontrols/ControlButton.m egl_bridge.c input_bridge_v3.c utils.c)
target_link_libraries(pojavexec
    "-F${CMAKE_CURRENT_LIST_DIR}/resources/Frameworks"
    "-framework UIKit"
    "-framework MetalANGLE"
    "-framework CoreGraphics"
    "-framework AuthenticationServices"
    "-Wl,-undefined -Wl,dynamic_lookup"
)
