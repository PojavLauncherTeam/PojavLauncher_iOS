cmake_minimum_required(VERSION 3.6)
project(PojavLauncher)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fcommon -fobjc-arc -ObjC -I'${CMAKE_CURRENT_LIST_DIR}/resources/Frameworks/MetalANGLE.framework/Headers' -I'${CMAKE_CURRENT_LIST_DIR}/external/DBNumberedSlider/Classes'"
)

set(CMAKE_SHARED_LINKER_FLAGS "'${CMAKE_SHARED_LINKER_FLAGS}' -rpath @executable_path/Frameworks -rpath @loader_path/Frameworks")

set(CMAKE_EXE_LINKER_FLAGS "'${CMAKE_EXE_LINKER_FLAGS}' -rpath @executable_path/Frameworks -rpath @loader_path/Frameworks")

add_library(pojavexec SHARED
  AboutLauncherViewController.m
  AppDelegate.m
  CustomControlsViewController.m
  LauncherFAQViewController.m
  LauncherPreferences.m
  LauncherPreferencesViewController.m
  LauncherViewController.m
  LoginViewController.m
  SceneDelegate.m 
  SurfaceViewController.m
  UpdateHistoryViewController.m
  customcontrols/ControlButton.m
  customcontrols/CustomControlsUtils.m
  egl_bridge.m
  external/DBNumberedSlider/Classes/DBNumberedSlider.m
  input_bridge_v3.m
  ios_uikit_bridge.m
  log.m
  utils.m
)
target_link_libraries(pojavexec
    "-F'${CMAKE_CURRENT_LIST_DIR}/resources/Frameworks'"
    "-framework UIKit"
    "-framework MetalANGLE"
    "-framework CoreGraphics"
    "-framework AuthenticationServices"
    "-Wl,-undefined -Wl,dynamic_lookup"
)

add_executable(PojavLauncher
  main.m
  log.m
  JavaLauncher.m)
target_link_libraries(PojavLauncher
    "-L'${CMAKE_CURRENT_LIST_DIR}/build'"
    "-framework UIKit -lpojavexec"
)
set_target_properties(PojavLauncher PROPERTIES
  MACOSX_BUNDLE TRUE
  MACOSX_FRAMEWORK_IDENTIFIER org.cmake.ExecutableTarget
  MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_LIST_DIR}/Info.plist")
