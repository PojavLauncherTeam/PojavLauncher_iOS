cmake_minimum_required(VERSION 3.6)
project(PojavLauncher)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -target arm64-apple-ios -fcommon -fobjc-arc -ObjC")
set(CMAKE_C_FLAGS_DEBUG "-funwind-tables -g")

if("${CMAKE_HOST_SYSTEM_NAME}" MATCHES "Linux|^GNU$|Android")
set(GLOBAL_LDFLAGS "-isysroot ${CMAKE_OSX_SYSROOT} -Wl,-syslibroot,${CMAKE_OSX_SYSROOT} -fuse-ld=lld")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${GLOBAL_LDFLAGS}")
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${GLOBAL_LDFLAGS}")
endif()

include_directories(
  "resources/Frameworks/Alderis.framework/Headers"
  "external/AFNetworking/AFNetworking"
  "external/AFNetworking/UIKit+AFNetworking"
  "external/DBNumberedSlider/Classes"
  "external/TOInsetGroupedTableView/TOInsetGroupedTableView"
  "external/fishhook"
  "external/mesa"
  "external/Apple"
)

# For cacio support library
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -rpath @loader_path -rpath @executable_path/jvm/java-8-openjdk/lib -rpath /usr/lib/jvm/java-8-openjdk/lib")

add_definitions(-DCONFIG_BRANCH="${CONFIG_BRANCH}")
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
  awt_headless
)

set(CMAKE_FRAMEWORK_PATH "${CMAKE_CURRENT_LIST_DIR}/resources/Frameworks")

set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -rpath @executable_path/Frameworks -rpath @loader_path/Frameworks")
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -rpath @executable_path/Frameworks -rpath @loader_path/Frameworks")


find_library(OSMESA_LIB libOSMesa.8.dylib)

add_library(libOSMesaOverride.dylib SHARED gl_mesa3d_patch.m)
set_target_properties(libOSMesaOverride.dylib PROPERTIES
    FRAMEWORK TRUE
    MACOSX_FRAMEWORK_IDENTIFIER dylib.mesa3d.libOSMesaOverride
)
target_link_libraries(libOSMesaOverride.dylib
  "${GLOBAL_LDFLAGS}"
  "${OSMESA_LIB}"
)


add_library(tinygl4angle SHARED
  external/gl4es/string_utils.c
  external/gl4es/tinygl4angle.c
)
target_link_libraries(tinygl4angle
  "${GLOBAL_LDFLAGS}"
  "-F'${CMAKE_CURRENT_LIST_DIR}/resources/Frameworks'"
  "-framework MetalANGLE"
)


add_executable(PojavLauncher
  external/AFNetworking/AFNetworking/AFSecurityPolicy.m
  external/AFNetworking/AFNetworking/AFHTTPSessionManager.m
  external/AFNetworking/AFNetworking/AFURLRequestSerialization.m
  external/AFNetworking/AFNetworking/AFURLSessionManager.m
  external/AFNetworking/AFNetworking/AFNetworkReachabilityManager.m
  external/AFNetworking/AFNetworking/AFURLResponseSerialization.m
  external/AFNetworking/UIKit+AFNetworking/AFNetworkActivityIndicatorManager.m
  external/AFNetworking/UIKit+AFNetworking/AFAutoPurgingImageCache.m
  external/AFNetworking/UIKit+AFNetworking/AFImageDownloader.m
  external/AFNetworking/UIKit+AFNetworking/UIButton+AFNetworking.m
  external/AFNetworking/UIKit+AFNetworking/UIImageView+AFNetworking.m

  main.m
  main_hook.m
  log.m
  JavaLauncher.m
  external/fishhook/fishhook.c
  UIKit+hook.m

  authenticator/BaseAuthenticator.m
  authenticator/LocalAuthenticator.m
  authenticator/MicrosoftAuthenticator.m
 
  customcontrols/ControlButton.m
  customcontrols/ControlDrawer.m
  customcontrols/ControlLayout.m
  customcontrols/ControlSubButton.m
  customcontrols/CustomControlsUtils.m

  external/DBNumberedSlider/Classes/DBNumberedSlider.m
  external/TOInsetGroupedTableView/TOInsetGroupedTableView/TOInsetGroupedTableView.m

  input/ControllerInput.m
  input/KeyboardInput.m

  AboutLauncherViewController.m
  AccountListViewController.m
  AppDelegate.m
  CustomControlsViewController.m
  FileListViewController.m
  GameSurfaceView.m
  JavaGUIViewController.m
  LauncherFAQViewController.m
  LauncherMenuViewController.m
  LauncherNavigationController.m
  LauncherNewsViewController.m
  LauncherPreferences.m
  LauncherPreferencesViewController2.m
  LauncherPrefGameDirViewController.m
  LauncherSplitViewController.m
  LoginViewController.m
  MinecraftResourceUtils.m
  SceneDelegate.m 
  SurfaceViewController.m
  UpdateHistoryViewController.m
  egl_bridge.m
  input_bridge_v3.m
  ios_uikit_bridge.m
  log.m
  utils.m
)

if("${CMAKE_HOST_SYSTEM_NAME}" MATCHES "Linux|^GNU$|Android")
target_sources(PojavLauncher PUBLIC non_darwin_utils.m)
endif()

target_link_libraries(PojavLauncher
  "-F'${CMAKE_CURRENT_LIST_DIR}/build'"
  "-F'${CMAKE_CURRENT_LIST_DIR}/resources/Frameworks'"
  "-framework AuthenticationServices"
  "-framework CoreGraphics"
  "-framework CoreServices"
  "-framework GameController"
  "-framework QuartzCore"
  "-framework SafariServices"
  "-framework Security"
  "-framework SystemConfiguration"
  "-framework UIKit"
  "-framework WebKit"
)
set_target_properties(PojavLauncher PROPERTIES
  MACOSX_BUNDLE TRUE
  MACOSX_FRAMEWORK_IDENTIFIER org.cmake.ExecutableTarget
  MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_LIST_DIR}/Info.plist")
