import Swift

struct LauncherProfiles: Encodable, Hashable {
    var selectedProfile = "(Default)"
    var profiles = [
        Profile(defaultGamepadCtrl: "", defaultTouchCtrl: "", gameDir: "test", icon: "https://static.wikia.nocookie.net/minecraft_gamepedia/images/6/62/Bricks_JE5_BE3.png/revision/latest/top-crop/width/40/height/40?cb=20200226015249", javaArgs: "-Dabc=def", javaVersion: "", renderer: "libgl4es.dylib", name: "test", lastVersionId: "1.21"),
        Profile(name: "empty", lastVersionId: "1.7.10")
    ]
}
