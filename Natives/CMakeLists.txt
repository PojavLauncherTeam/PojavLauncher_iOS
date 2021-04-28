cmake_minimum_required(VERSION 3.6)
project(PojavLauncher)

# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
set(CMAKE_C_FLAGS "-fobjc-arc -x objective-c -Iresources/Frameworks/MetalANGLE.framework/Headers")

add_executable(PojavLauncher main.c log.m JavaLauncher.c)
target_link_libraries(PojavLauncher
    "-framework UIKit"
)
set_target_properties(PojavLauncher PROPERTIES
  MACOSX_BUNDLE TRUE
  MACOSX_FRAMEWORK_IDENTIFIER org.cmake.ExecutableTarget
  MACOSX_BUNDLE_INFO_PLIST "../Info.plist")

add_library(pojavexec SHARED log.m AppDelegate.m SceneDelegate.m UILauncher.m LauncherViewController.m LoginViewController.m SurfaceViewController.m egl_bridge_ios.m ios_uikit_bridge.m customcontrols/ControlButton.m egl_bridge.c input_bridge_v3.c utils.c)
target_link_libraries(pojavexec
    "-Fresources/Frameworks"
    "-framework UIKit"
    "-framework MetalANGLE"
    "-framework CoreGraphics"
    "-framework AuthenticationServices"
)
