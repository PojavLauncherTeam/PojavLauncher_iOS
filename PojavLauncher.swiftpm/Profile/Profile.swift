import SwiftUI

class Profile: Codable, ObservableObject {
    @Published var defaultGamepadCtrl: String?
    @Published var defaultTouchCtrl: String?
    @Published var gameDir: String?
    @Published var icon: String?
    @Published var javaArgs: String?
    @Published var javaVersion: String?
    @Published var renderer: String?
    @Published var name: String = "New Profile"
    @Published var lastVersionId: String = "latest-release"
    /*
    init(defaultGamepadCtrl: String?, defaultTouchCtrl: String?, gameDir: String?, icon: String?, javaArgs: String?, javaVersion: Sting?, renderer: String?, name: String?, lastVersionId: String?) {
        
    }
*/
}
