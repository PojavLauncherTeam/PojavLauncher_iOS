# PojavLauncher
[![Development build](https://github.com/PojavLauncherTeam/PojavLauncher_iOS/actions/workflows/development.yml/badge.svg?branch=main)](https://github.com/PojavLauncherTeam/PojavLauncher_iOS/actions/workflows/development.yml)
[![Crowdin](https://badges.crowdin.net/pojavlauncher/localized.svg)](https://crowdin.com/project/pojavlauncher)
[![Discord](https://img.shields.io/discord/724163890803638273.svg?label=&logo=discord&logoColor=ffffff&color=7389D8&labelColor=6A7EC2)](https://discord.gg/x5pxnANzbX)
[![Reddit](https://img.shields.io/badge/dynamic/json.svg?label=r/PojavLauncher%20member%20count&query=$.data.subscribers&url=https://www.reddit.com/r/PojavLauncher/about.json)](https://reddit.com/r/PojavLauncher)

## Note
- The official Twitter for PojavLauncher is [@PLaunchTeam](https://twitter.com/PLaunchTeam). Any others (most notably @PojavLauncher) are fake, please report them to Twitter's moderation team.

## Introduction
- PojavLauncher is a Minecraft: Java Edition launcher for Android and iOS based on [Boardwalk](https://github.com/zhuowei/Boardwalk).
- This launcher can launch most of available Minecraft versions (up to latest 1.19.2, including Combat Test versions).
- Modding via Forge and Fabric are also supported.
- Older versions of Forge and Fabric can be used with OpenJDK 8.
- This repository contains source code for iOS/iPadOS platform.
- For Android platform, check out [PojavLauncher repository](https://github.com/PojavLauncherTeam/PojavLauncher).

## Getting started with PojavLauncher

The [PojavLauncher Website](https://pojavlauncherteam.github.io/INSTALL.html#ios) has extensive documentation on how to install, set up, and play! For those who wish to install quickly, here's the basics (on iOS 12 or later):

Note: This is experimental, although game works smoothly, you should not set Render distance too much.

1. Setup the sideload app
- For iOS 14.0-15.5beta4, [TrollStore](https://github.com/opa334/TrollStore) is recommended to keep PojavLauncher permanently signed and have JIT enabled by itself.
- Otherwise, install [AltStore](https://altstore.io). Others will also work.
2. Download an IPA build of PojavLauncher in the Actions tab.
3. Open the downloaded IPA in the sideload app to install.
4. For enabling JIT, choose one of these:
 - Setup [JitStreamer](http://jitstreamer.com), then launch PojavLauncher. JIT will be automatically enabled on startup. This is the most convenient way.
 - Be jailbroken (JIT will automatically be enabled)
 - Install with TrollStore (JIT will automatically be enabled)
 - Launch PojavLauncher with `Enable JIT` option in AltStore. This requires the device to be plugged in the computer or have Wi-Fi syncing enabled.
 - Setup and use others such as [Jitterbug](https://github.com/osy/Jitterbug).

## Known issues
* Some Forge versions may fail with `java.lang.reflect.InvocationTargetException`.
* The game will be prone to JetsamEvents.

## Contributors
PojavLauncher is amazing, and surprisingly stable, and it wouldn't be this way without the commmunity that helped and contribute to the project! Some notable names:

@khanhduytran0 - Lead iOS port developer  
@crystall1nedev - Lead iOS port developer  
@artdeell  
@Mathius-Boulay  
@zhuowei  
@jkcoxson   
@Diatrus 

## Third party components and their licenses
- [Caciocavallo](https://github.com/PojavLauncherTeam/caciocavallo): [GNU GPLv2 License](https://github.com/PojavLauncherTeam/caciocavallo/blob/master/LICENSE).
- [jsr305](https://code.google.com/p/jsr-305): [3-Clause BSD License](http://opensource.org/licenses/BSD-3-Clause).
- [org.json](https://github.com/stleary/JSON-java): [The JSON License](https://www.json.org/license.html).
- [Boardwalk](https://github.com/zhuowei/Boardwalk): [Apache 2.0 License](https://github.com/zhuowei/Boardwalk/blob/master/LICENSE)
- [GL4ES](https://github.com/ptitSeb/gl4es) by @lunixbochs @ptitSeb: [MIT License](https://github.com/ptitSeb/gl4es/blob/master/LICENSE).
- [Mesa 3D Graphics Library](https://gitlab.freedesktop.org/mesa/mesa): [MIT License](https://docs.mesa3d.org/license.html).
- [MetalANGLE](https://github.com/kakashidinho/metalangle) by @kakashidinho and ANGLE team: [BSD 2.0 License](https://github.com/kakashidinho/metalangle/blob/master/LICENSE).
- [MoltenVK](https://github.com/KhronosGroup/MoltenVK): [Apache 2.0 License](https://github.com/KhronosGroup/MoltenVK/blob/master/LICENSE).
- [Azul Zulu JDK](https://www.azul.com/downloads/?package=jdk): [GNU GPLv2 License](https://openjdk.java.net/legal/gplv2+ce.html).
- [LWJGL3](https://github.com/PojavLauncherTeam/lwjgl3): [BSD-3 License](https://github.com/LWJGL/lwjgl3/blob/master/LICENSE.md).
- [LWJGLX](https://github.com/PojavLauncherTeam/lwjglx) (LWJGL2 API compatibility layer for LWJGL3): unknown license.
- [Alderis](https://github.com/hbang/Alderis) (color picker for iOS < 14): [Apache 2.0 License](https://github.com/hbang/Alderis/blob/master/LICENSE.md).
- [DBNumberedSlider](https://github.com/immago/DBNumberedSlider): [Apache 2.0 License](https://github.com/immago/DBNumberedSlider/blob/master/LICENSE)
- [fishhook](https://github.com/facebook/fishhook) (jailed environment usage only): [BSD-3 License](https://github.com/facebook/fishhook/blob/main/LICENSE).
- [Java Native Access](https://github.com/java-native-access/jna): [Apache 2.0 License](https://github.com/java-native-access/jna/blob/master/LICENSE).
- [shaderc](https://github.com/google/shaderc) (used by mods that uses Vulkan for rendering): [Apache 2.0 License](https://github.com/google/shaderc/blob/main/LICENSE).
- [TOInsetGroupedTableView](https://github.com/TimOliver/TOInsetGroupedTableView): [MIT License](https://github.com/TimOliver/TOInsetGroupedTableView/blob/master/LICENSE).
- [AltKit](https://github.com/rileytestut/AltKit)
- Thanks to [MCHeads](https://mc-heads.net) for providing Minecraft avatars.

## Special thanks to MacStadium!
This project is listed under the MacStadium Open Source Program, which allows all of us developers to keep on moving forward even without physical access to a Mac.

![](https://user-images.githubusercontent.com/55281754/183129754-c3736bb9-d528-4af7-9351-a12b3be7549e.png)

<!-- sillysock was here -->
