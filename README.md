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
- Not finished yet!
- There's no eta on this project.

## How can it work?
- Use OpenJDK 16 from Procursus to get real Java environment.
- (Temporary) Use JavaFX to get a fresh GLES context.
- Use GL4ES for OpenGL -> OpenGL ES translator.
- Use our [LWJGL3 iOS port](https://github.com/PojavLauncherTeam/lwjgl3).
- Use same launch method as PojavLauncher Android.

## Installing OpenJDK 16
- Download [openjdk-16-jre • Procursus](https://www.ios-repo-updates.com/repository/procursus/package/openjdk-16-jre) .deb file (~40mb).

### For jailbroken iOS device (without Procursus)
- ssh to iOS or use a terminal, type these commands
```
# Grant root access
su

# Install use dpkg
dpkg -i /path/to/openjdk-16-jre.deb

# Verify if java is installed
/usr/lib/jvm/java-16-openjdk/bin/java -version
```

### For non-jailbroken devices
- idk maybe unpack deb file?

## Credits & Third party components and their licenses
- [OpenJDK 16](https://www.ios-repo-updates.com/repository/procursus/package/openjdk-16-jre): GNU GPLv2 license.
- GL4ES
- Boardwalk JVM Launcher.

