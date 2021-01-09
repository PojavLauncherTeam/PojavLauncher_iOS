![iOS build](https://github.com/PojavLauncherTeam/PojavLauncher_iOS/workflows/iOS%20build/badge.svg)

# PojavLauncher_iOS
Minecraft: Java Edition launcher for iOS, based on [PojavLauncher Android](https://github.com/PojavLauncherTeam/PojavLauncher).

## Navigation
- [Introduction](#introduction)
- [Building](#building)
- [How can it work?](#How-can-it-work?)
- [Current status](#current-status)
- [License](#license)
- [Contributing](#contributing)
- [Credits & Third party components and their licenses](#credits--third-party-components-and-their-licenses)

## Introduction
- This is an attempt to get Minecraft Java run on a jailbroken iOS.

## Building
Requirements:
- Mac OS X (tested: 10.15)
- XCode (tested: 11.7.0)
- JDK 1.8 installed
- `gradle` to build Java part.
- `ldid`, `dpkg` and `fakeroot` to package.
Run in this directory
```
# Install required packages
brew install ldid dpkg fakeroot gradle

# Build natives part
bash build_natives.sh

# Build java part
bash build_javaapp.sh

# Sign with entitlements and package
bash build_package.sh
```

## How can it work?
- Use OpenJDK 16 from Procursus to get real Java environment.
- Use GL4ES for OpenGL -> OpenGL ES translator.
- Use our [LWJGL3 iOS port](https://github.com/PojavLauncherTeam/lwjgl3).
- Use same launch method as PojavLauncher Android.

## Current status
- [x] Java Runtime Environment: OpenJDK 16.
- [x] LWJGL3 iOS port: works
- [x] OpenGL: GL4ES
- [x] Did Minecraft recognize OpenGL?
- [ ] OpenAL: not included yet, maybe use iOS built-in OpenAL?
- [ ] Input pipe implementation
- [ ] Does it work? Partial.
- Currently, only rd-132211 and are-132328 (oldest Minecraft versions :V) fully works.
- 1.6.x only render a tiny panorama at bottom left corner.
- 1.7.2 to 1.12.2 will crash because of framebuffer.
- Other versions will crash for various reasons: missing LWJGL JNI methods, missing OpenAL, Narrator crash, etc...
- It may crash sometimes, but try launch again until you get it works.

## Installing OpenJDK 16
- Download [openjdk-16-jre • Procursus](https://www.ios-repo-updates.com/repository/procursus/package/openjdk-16-jre) .deb file (~40mb).

### For Odyssey bootstrap
- Add Procursus repository (https://apt.procurs.us).
- Find and install `java-16-openjdk`.

### For other jailbreak bootstrap
- Download [openjdk-16-jre.deb](https://github.com/PojavLauncherTeam/PojavLauncher_iOS/releases/download/v16-openjdk/openjdk-16-jre_16.0.0_iphoneos-arm.deb).
- Install and open Filza File manager.
- Go to where the .deb file downloaded.
- Open it and press Install.
- If everything fine, it will ends up with `Setting up ...`.

## Want a try or debug?
- Minecraft home directory: `/var/mobile/Documents/minecraft`.
- Select a version: edit `/var/mobile/Documents/minecraft/config_ver.txt`, put to Minecraft version want to start.


## License
- PojavLauncher is licensed under [GNU GPLv3](https://github.com/khanhduytran0/PojavLauncher_iOS/blob/master/LICENSE).

## Contributing
Contributions are welcome! We welcome any type of contribution, not only code. Any code change should be submitted as a pull request. The description should explain what the code does and give steps to execute it.

## Credits & Third party components and their licenses
- [Boardwalk](https://github.com/zhuowei/Boardwalk) (JVM Launcher): Unknown License/[Apache License 2.0](https://github.com/zhuowei/Boardwalk/blob/master/LICENSE) or GNU GPLv2.
- [GL4ES](https://github.com/ptitSeb/gl4es) by @ptitSeb: [MIT License](https://github.com/ptitSeb/gl4es/blob/master/LICENSE).<br>
- [OpenJDK 16](https://www.ios-repo-updates.com/repository/procursus/package/openjdk-16-jre) porter to iOS by @Diatrus: [GNU GPLv2 License](https://openjdk.java.net/legal/gplv2+ce.html).<br>
- [LWJGL3](https://github.com/PojavLauncherTeam/lwjgl3): [BSD-3 License](https://github.com/LWJGL/lwjgl3/blob/master/LICENSE.md).
- [LWJGLX](https://github.com/PojavLauncherTeam/lwjglx) (LWJGL2 API compatibility layer for LWJGL3): unknown license.<br>
