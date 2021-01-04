# PojavLauncher_iOS
Minecraft: Java Edition launcher for iOS, based on [PojavLauncher Android](https://github.com/PojavLauncherTeam/PojavLauncher).

## Navigation
- [Introduction](#introduction)
- [Building](#building)
- [Current status](#current-status)
- [License](#license)
- [Contributing](#contributing)
- [Credits & Third party components and their licenses](#credits--third-party-components-and-their-licenses)

## Introduction
- This is an attempt to get Minecraft Java run on a jailbroken iOS.
- There's no eta on this project.

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
- [ ] Does it work?
- Current error: `GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT` tested on Minecraft 1.13, 1.14 and 1.15.2 (probably all other versions).

## Installing OpenJDK 16
- Download [openjdk-16-jre • Procursus](https://www.ios-repo-updates.com/repository/procursus/package/openjdk-16-jre) .deb file (~40mb).

### For jailbroken iOS device
- Jailbreak use Odyssey
- Add Procursus repository (https://apt.procurs.us).
- Find and install `java-16-openjdk`.

### For non-jailbroken devices
- It’s not possible...

## Want a try or debug?
- Minecraft home directory: `/var/mobile/Documents/minecraft`.
- Select a version: edit `/var/mobile/Documents/minecraft/config_ver.txt`, put to Minecraft version want to start.


## License
- PojavLauncher is licensed under [GNU GPLv3](https://github.com/khanhduytran0/PojavLauncher_iOS/blob/master/LICENSE).

## Contributing
Contributions are welcome! We welcome any type of contribution, not only code. Any code change should be submitted as a pull request. The description should explain what the code does and give steps to execute it.

## Credits & Third party components and their licenses
- [Boardwalk](https://github.com/zhuowei/Boardwalk) (JVM Launcher): Unknown License/[Apache License 2.0](https://github.com/zhuowei/Boardwalk/blob/master/LICENSE) or GNU GPLv2.
- [GL4ES](https://github.com/ptitSeb/gl4es): [MIT License](https://github.com/ptitSeb/gl4es/blob/master/LICENSE).<br>
- [OpenJDK](https://www.ios-repo-updates.com/repository/procursus/package/openjdk-16-jre): [GNU GPLv2 License](https://openjdk.java.net/legal/gplv2+ce.html).<br>
- [LWJGL3](https://github.com/PojavLauncherTeam/lwjgl3): [BSD-3 License](https://github.com/LWJGL/lwjgl3/blob/master/LICENSE.md).
- [LWJGLX](https://github.com/PojavLauncherTeam/lwjglx) (LWJGL2 API compatibility layer for LWJGL3): unknown license.<br>
