# PojavLauncher
![iOS build](https://github.com/PojavLauncherTeam/PojavLauncher_iOS/workflows/iOS%20build/badge.svg)
[![Discord](https://img.shields.io/discord/724163890803638273.svg?label=&logo=discord&logoColor=ffffff&color=7389D8&labelColor=6A7EC2)](https://discord.gg/x5pxnANzbX)
[![Reddit](https://img.shields.io/badge/dynamic/json.svg?label=r/PojavLauncher%20member%20count&query=$.data.subscribers&url=https://www.reddit.com/r/PojavLauncher/about.json)](https://reddit.com/r/PojavLauncher)

## Note
- The official Twitter for PojavLauncher is [@PLaunchTeam](https://twitter.com/PLaunchTeam). Any others (most notably @PojavLauncher) are fake, please report them to Twitter's moderation team.

## Introduction
PojavLauncher is a Minecraft: Java Edition launcher for Android and iOS based on [Boardwalk](https://github.com/zhuowei/Boardwalk). This launcher can launch most of available Minecraft versions (from 1.6.1 to 1.18, including Combat Test versions). 1.17+ support is available as of v2.0, or with the workarounds described on our [website](https://pojavlauncherteam.github.io). Modding via Forge (1.16.x only) and Fabric are also supported. Older versions of Forge and Fabric can be used with OpenJDK 8. This repository contains source code for iOS/iPadOS platform. For Android platform, check out [PojavLauncher repository](https://github.com/PojavLauncherTeam/PojavLauncher).

This launcher is available on the Procursus repo, thanks to [@Diatrus](https://twitter.com/Diatrus), and Doregon's Repository, thanks to [@Doregon](https://twitter.com/AdamTunnic)

## Getting started with PojavLauncher

The [PojavLauncher Website](https://pojavlauncherteam.github.io) has extensive documentation on how to install, set up, and play! For those who wish to install quickly, here's the basics (on iOS 12 or later):

### Procursus-bootstraps
*Note: This is currently unavailable. Will be fixed soon!*
If you have Chimera, Taurine, Odyssey, or another jailbreak that comes with **libhooker**, this one's for you.

1. Search for `pojavlauncher` with your favorite package manager.
2. Install `PojavLauncher iOS`.

### Bingner/Elucubratus bootstraps
If you have unc0ver, checkra1n, or another jailbreak that comes with **Cydia Substrate** or **Substitute**, this one's for you. You can also use this if you have a libhooker jailbreak.

1. Add `https://apt.doregon.gq` to your sources list.
2. Search for `pojavlauncher` with your favorite package manager.
3. Install the package you wish to have, according to your preference:
   * `pojavlauncher.release` is the stable build. This one gets updated with new releases or tags on this repository, or when Procursus updated their copy.
   * `pojavlauncher.development` is the latest commit on the `main` branch of this repository. It may have application breaking bugs, but also has more features.
   * The rootless variants serve the same purpose, but only work with Procursus jailbreaks and iOS 15 (see our website for more information).

## Known issues
* Minecraft 1.12.2 and below are very buggy: you can't type text, random crashes, etc...
* When using certain versions, the camera may jump to a random position when you start to touch the screen.
* Some Forge versions may fail with `java.lang.reflect.InvocationTargetException`.
* The game will be prone to JetsamEvents.

## Work in progress
* Custom controls

## Contributors
PojavLauncher is amazing, and surprisingly stable, and it wouldn't be this way without the following people that helped and contribute to the project!

@khanhduytran0 - Lead iOS port developer  
@Doregon - PojavLauncher hosting on Doregon's Repository, iOS port developer  
@artdeell - Lead developer  
@LegacyGamerHD - Lead developer  
@zhouwei - Original Boardwalk code  
@Mathius-Boulay - Developer   
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


<!-- Ava was here -->
