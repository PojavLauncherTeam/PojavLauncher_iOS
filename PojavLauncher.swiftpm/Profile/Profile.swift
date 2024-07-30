import Swift

struct Profile: Encodable, Hashable {
    var defaultGamepadCtrl, defaultTouchCtrl, gameDir, icon, javaArgs, javaVersion, renderer: String?
    var name, lastVersionId: String
}
