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

This launcher is available on the Procursus repo, thanks to [@Diatrus](https://twitter.com/Diatrus), and Doregon's Repository, thanks to [@crystall1ndev](https://twitter.com/crystall1nedev)

## Getting started with PojavLauncher

The [PojavLauncher Website](https://pojav.ml) has extensive documentation on how to install, set up, and play! For those who wish to install quickly, here's the basics (on iOS 12 or later):

### Without jailbreak (sideload as IPA)
Note: This is experimental, although game works smoothly, you should not set Render distance too much.

1. Setup the sideload app
- For iOS 14.0-15.5beta4 on compatible devices, [TrollStore](https://github.com/opa334/TrollStore) is recommended to keep PojavLauncher permanently signed and have JIT enabled by itself.
- Otherwise, install [AltStore](https://altstore.io). Others will also work.
2. Download an IPA build of PojavLauncher in the Actions tab.
3. Open the downloaded IPA in the sideload app to install.
4. For enabling JIT, choose one of these:
 - Setup [JitStreamer](http://jitstreamer.com), then launch PojavLauncher. JIT will be automatically enabled on startup. This is the most convenient way.
 - Launch PojavLauncher with `Enable JIT` option in AltStore. This requires the device to be plugged in the computer or have Wi-Fi syncing enabled.
 - Setup and use others such as [Jitterbug](https://github.com/osy/Jitterbug).

### Procursus-bootstraps
*Note: This is currently unavailable. Will be fixed soon! For the meantime, you can follow the same way as [below](#bingnerelucubratus-bootstraps)*.
If you have Chimera, Taurine, Odyssey, or another jailbreak that comes with **libhooker**, this one's for you.

1. Search for `pojavlauncher` with your favorite package manager.
2. Install `PojavLauncher iOS`.

### Bingner/Elucubratus bootstraps
If you have unc0ver, checkra1n, or another jailbreak that comes with **Cydia Substrate** or **Substitute**, this one's for you. You can also use this if you have a libhooker jailbreak.

1. Add `https://repository.crystall1ne.software` to your sources list.
2. Search for `pojavlauncher` with your favorite package manager.
3. Install the package you wish to have, according to your preference:
   * `pojavlauncher.release` is the stable build. This one gets updated with new releases or tags on this repository, or when Procursus updated their copy.
   * `pojavlauncher.development` is the latest commit on the `main` branch of this repository. It may have application breaking bugs, but also has more features.
   * The rootless variants serve the same purpose, but only work with Procursus jailbreaks and iOS 15 (see our website for more information).

## Known issues
* Some Forge versions may fail with `java.lang.reflect.InvocationTargetException`.
* The game will be prone to JetsamEvents.

## Contributors
PojavLauncher is amazing, and surprisingly stable, and it wouldn't be this way without the following people that helped and contribute to the project!

@khanhduytran0 - Lead iOS port developer  
@crystall1nedev - Lead iOS port developer  
@artdeell - Lead developer  
@LegacyGamerHD - Lead developer  
@zhouwei - Original Boardwalk code  
@Mathius-Boulay - Developer   
@jkcoxson - JitStreamer author   
@Diatrus - PojavLauncher hosting on Procursus  
@Syjalo  
@pedrosouzabrasil  
@notfoundname  
@buzybox11  
@RealEthanPlayzDev  
@HongyiMC  
@thecoder08  
@genericrandom64  

## Third party components and their licenses
- [Caciocavallo](https://github.com/PojavLauncherTeam/caciocavallo): [GNU GPLv2 License](https://github.com/PojavLauncherTeam/caciocavallo/blob/master/LICENSE).
- [jsr305](https://code.google.com/p/jsr-305): [3-Clause BSD License](http://opensource.org/licenses/BSD-3-Clause).
- [org.json](https://github.com/stleary/JSON-java): [The JSON License](https://www.json.org/license.html).
- [Boardwalk](https://github.com/zhuowei/Boardwalk): [Apache 2.0 License](https://github.com/zhuowei/Boardwalk/blob/master/LICENSE)
- [GL4ES](https://github.com/ptitSeb/gl4es) by @lunixbochs @ptitSeb: [MIT License](https://github.com/ptitSeb/gl4es/blob/master/LICENSE).
- [Mesa 3D Graphics Library](https://gitlab.freedesktop.org/mesa/mesa): [MIT License](https://docs.mesa3d.org/license.html).
- [MetalANGLE](https://github.com/kakashidinho/metalangle) by @kakashidinho and ANGLE team: [BSD 2.0 License](https://github.com/kakashidinho/metalangle/blob/master/LICENSE).
- [MoltenVK](https://github.com/KhronosGroup/MoltenVK): [Apache 2.0 License](https://github.com/KhronosGroup/MoltenVK/blob/master/LICENSE).
- [OpenJDK 16](https://www.ios-repo-updates.com/repository/procursus/package/openjdk-16-jre) ported to iOS by @Diatrus: [GNU GPLv2 License](https://openjdk.java.net/legal/gplv2+ce.html).
- [LWJGL3](https://github.com/PojavLauncherTeam/lwjgl3): [BSD-3 License](https://github.com/LWJGL/lwjgl3/blob/master/LICENSE.md).
- [LWJGLX](https://github.com/PojavLauncherTeam/lwjglx) (LWJGL2 API compatibility layer for LWJGL3): unknown license.
- [Alderis](https://github.com/hbang/Alderis) (color picker for iOS < 14): [Apache 2.0 License](https://github.com/hbang/Alderis/blob/master/LICENSE.md).
- [DBNumberedSlider](https://github.com/immago/DBNumberedSlider): [Apache 2.0 License](https://github.com/immago/DBNumberedSlider/blob/master/LICENSE)
- [fishhook](https://github.com/facebook/fishhook) (jailed environment usage only): [BSD-3 License](https://github.com/facebook/fishhook/blob/main/LICENSE).
- [Java Native Access](https://github.com/java-native-access/jna): [Apache 2.0 License](https://github.com/java-native-access/jna/blob/master/LICENSE).
- [shaderc](https://github.com/google/shaderc) (used by mods that uses Vulkan for rendering): [Apache 2.0 License](https://github.com/google/shaderc/blob/main/LICENSE).
- [TOInsetGroupedTableView](https://github.com/TimOliver/TOInsetGroupedTableView): [MIT License](https://github.com/TimOliver/TOInsetGroupedTableView/blob/master/LICENSE).

## Special thanks to MacStadium!
This project is listed under the MacStadium Open Source Program, which allows all of us developers to keep on moving forward even without physical access to a Mac.

![](https://user-images.githubusercontent.com/55281754/183129754-c3736bb9-d528-4af7-9351-a12b3be7549e.png)

<!-- sillysock was here -->
