cmake_minimum_required(VERSION 3.6)
project(PojavLauncher)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fcommon -fobjc-arc -ObjC -I'${CMAKE_CURRENT_LIST_DIR}/resources/Frameworks/MetalANGLE.framework/Headers' -I'${CMAKE_CURRENT_LIST_DIR}/external/DBNumberedSlider/Classes' -I'${CMAKE_CURRENT_LIST_DIR}/external/fishhook' -I'${CMAKE_CURRENT_LIST_DIR}/external_include'"
)
set(CMAKE_C_FLAGS_DEBUG "-funwind-tables -g")

# For cacio support library
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -rpath /usr/lib/jvm/java-8-openjdk/lib")

add_definitions(-DCONFIG_COMMIT="${CONFIG_COMMIT}")
add_definitions(-DCONFIG_RELEASE=${CONFIG_RELEASE})

# EXT: stub library, delete after compile awt_xawt
add_library(awt_headless SHARED
  awt_xawt/empty.m
)
target_link_libraries(awt_headless)

# EXT: cacio support library
add_library(awt_xawt SHARED
  awt_xawt/xawt_fake.m
)
target_link_libraries(awt_xawt
  "-L'${CMAKE_CURRENT_LIST_DIR}/build'"
  "-lawt_headless"
)

set(CMAKE_FRAMEWORK_PATH "${CMAKE_CURRENT_LIST_DIR}/resources/Frameworks")

set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -rpath @executable_path/Frameworks -rpath @loader_path/Frameworks")
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -rpath @executable_path/Frameworks -rpath @loader_path/Frameworks")

find_library(OSMESA_LIB libOSMesa.8.dylib)

add_library(libOSMesaOverride.dylib SHARED gl_mesa3d_patch.m)
set_target_properties(libOSMesaOverride.dylib PROPERTIES
    FRAMEWORK TRUE
)
target_link_libraries(libOSMesaOverride.dylib ${OSMESA_LIB})

add_library(PojavCore SHARED
  AboutLauncherViewController.m
  AppDelegate.m
  CustomControlsViewController.m
  JavaGUIViewController.m
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
set_target_properties(PojavCore PROPERTIES
    FRAMEWORK TRUE
)
target_link_libraries(PojavCore
  "-framework AuthenticationServices"
  "-framework CoreGraphics"
  "-framework QuartzCore"
  "-framework UIKit"
)

add_executable(PojavLauncher
  main.m
  log.m
  JavaLauncher.m
  external/fishhook/fishhook.c
)
target_link_libraries(PojavLauncher
  "-F'${CMAKE_CURRENT_LIST_DIR}/build'"
  "-framework PojavCore"
  "-framework UIKit"
)
set_target_properties(PojavLauncher PROPERTIES
  MACOSX_BUNDLE TRUE
  MACOSX_FRAMEWORK_IDENTIFIER org.cmake.ExecutableTarget
  MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_LIST_DIR}/Info.plist")
