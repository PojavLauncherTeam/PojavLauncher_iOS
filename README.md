![iOS build](https://github.com/PojavLauncherTeam/PojavLauncher_iOS/workflows/iOS%20build/badge.svg)
[![Discord](https://img.shields.io/discord/724163890803638273.svg?label=&logo=discord&logoColor=ffffff&color=7389D8&labelColor=6A7EC2)](https://discord.gg/6RpEJda)

# PojavLauncher_iOS
Minecraft: Java Edition launcher for iOS, based on [PojavLauncher Android](https://github.com/PojavLauncherTeam/PojavLauncher).

This launcher is now available at Procursus repository, thanks to @Diatrus!

## Navigation
- [Introduction](#introduction)
- [Building](#building)
- [How can it work?](#how-can-it-work)
- [Current status](#current-status)
- [Known issues](#known-issues)
- [License](#license)
- [Contributing](#contributing)
- [Credits & Third party components and their licenses](#credits--third-party-components-and-their-licenses)

## Introduction
- This is an attempt to get Minecraft Java run on a jailbroken iOS.
- Minimum requirements: device running iOS 12 or newer.

## Building
Requirements:
- Mac OS X (tested: 10.15)
- Xcode (tested: 11.7.0)
- Minimum iOS SDK: 13.4.
- JDK 8 installed
- `gradle` to build Java part.
- `cmake`, `wget`, `ldid`, `dpkg` and `fakeroot` to package.
Run in this directory
```
# Only run if you haven't installed JDK 8
brew install adoptopenjdk8

# Install required packages
brew install cmake wget ldid dpkg fakeroot gradle

# Give exec perm
chmod 755 *.sh

# Build natives part
./build_natives.sh

# Build java part
./build_javaapp.sh

# Sign with entitlements and package
./build_package.sh
```

## How can it work?
- Use OpenJDK 16 from Procursus to get real Java environment.
- Use MetalANGLE for OpenGL ES -> Metal translator.
- Use GL4ES for OpenGL -> OpenGL ES translator.
- Use our [LWJGL3 iOS port](https://github.com/PojavLauncherTeam/lwjgl3).
- Use same launch method as PojavLauncher Android.

## Current status
- [x] Java Runtime Environment: OpenJDK 16.
- [x] LWJGL3 iOS port: works
- [x] OpenGL: GL4ES
- [x] Did Minecraft recognize OpenGL?
- [x] OpenAL: use @kcat's openal-soft
- [x] Input pipe implementation
- [x] Account authentication (partial).
- [x] Does it work? Partial.
- Currently, only Minecraft 1.6.1+ tested to fully works.
- Forge (1.13+), Fabric and OptiFine works well.

## Known issues
- (Some versions) Camera position will be jumped to random location on first time touch.
- It might crash sometimes, but try launch again until you get it works.

## Installing OpenJDK 16
### For Chimera/Odyssey/Taurine jailbreak 
- Add Procursus repository (https://apt.procurs.us) (usually the Sileo package manager already comes with Procursus repo).
- Find and install `openjdk-16-jre`.

### For other jailbreak bootstraps
- Add Doregon's repository (https://doregon.github.io/cydia)
- Find and install `openjdk-16-jre`.

## Installing PojavLauncher
### For Chimera/Odyssey/Taurine jailbreak 
- Add Procursus repository (https://apt.procurs.us) (usually the Sileo package manager already comes with Procursus repo).
- Find and install `pojavlauncher`.

### For other jailbreak bootstraps
- Add Doregon's repository (https://doregon.github.io/cydia)
- Find and install `pojavlauncher` for the release version, or `pojavlauncher-dev` for the latest good commit.
    
## Directory locations
- Account json directory: `/var/mobile/Documents/.pojavlauncher/accounts`.
- Minecraft home directory: `/var/mobile/Documents/minecraft`.
- You can also customize JVM Arguments in `overrideargs.txt` on `minecraft` directory.

## License
- PojavLauncher is licensed under [GNU GPLv3](https://github.com/khanhduytran0/PojavLauncher_iOS/blob/master/LICENSE).

## Contributing
Contributions are welcome! We welcome any type of contribution, not only code. Any code change should be submitted as a pull request. The description should explain what the code does and give steps to execute it.

## Credits & Third party components and their licenses
- [Contributors of PojavLauncher Android](https://github.com/PojavLauncherTeam/PojavLauncher/graphs/contributors) and here.
- [Apache Commons](https://commons.apache.org): [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0.txt).
- [jsr305](https://code.google.com/p/jsr-305): [3-Clause BSD License](http://opensource.org/licenses/BSD-3-Clause).
- [org.json](https://github.com/stleary/JSON-java): [The JSON License](https://www.json.org/license.html).
- [Boardwalk](https://github.com/zhuowei/Boardwalk) (JVM Launcher): Unknown License/[Apache License 2.0](https://github.com/zhuowei/Boardwalk/blob/master/LICENSE) or GNU GPLv2.
- [GL4ES](https://github.com/ptitSeb/gl4es) by @lunixbochs @ptitSeb: [MIT License](https://github.com/ptitSeb/gl4es/blob/master/LICENSE).<br>
- [MetalANGLE](https://github.com/kakashidinho/metalangle) by @kakashidinho and ANGLE team: [BSD License 2.0](https://github.com/kakashidinho/metalangle/blob/master/LICENSE).
- [OpenJDK 16](https://www.ios-repo-updates.com/repository/procursus/package/openjdk-16-jre) ported to iOS by @Diatrus: [GNU GPLv2 License](https://openjdk.java.net/legal/gplv2+ce.html).<br>
- [LWJGL3](https://github.com/PojavLauncherTeam/lwjgl3): [BSD-3 License](https://github.com/LWJGL/lwjgl3/blob/master/LICENSE.md).
- [LWJGLX](https://github.com/PojavLauncherTeam/lwjglx) (LWJGL2 API compatibility layer for LWJGL3): unknown license.<br>
