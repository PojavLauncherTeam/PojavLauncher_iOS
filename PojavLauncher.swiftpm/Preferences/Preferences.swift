import UIKit

class Preferences: Codable, ObservableObject, Equatable {
    private static var saveChanges = true
    @Published var accounts: [UUID : Account] = [:]
    
    class General: Codable, ObservableObject {
        @Published var check_sha: Bool = true
        @Published var cosmetica: Bool = true
        @Published var debug_logging: Bool = false
        // var appicon: String
        @Published var game_directory: String? = "default"
    }
    @Published var general = General()
    
    class Video: Codable, ObservableObject {
        @Published var renderer: String = "auto"
        @Published var resolution: Double = 100
        @Published var max_framerate: Bool = true
        @Published var performance_hud: Bool = false
        @Published var fullscreen_airplay: Bool = true
        @Published var silence_other_audio: Bool = false
        @Published var silence_with_switch: Bool = false
    }
    @Published var video = Video()
    
    class Control: Codable, ObservableObject {
        @Published var default_ctrl: String = "default.json"
        @Published var control_safe_area: String = "" 
        // Sring(for insets: UIApplication.shared.windows.first.safeAreaInsets)
        @Published var default_gamepad_ctrl: String = "default.json"
        @Published var controller_type: String = "xbox"
        @Published var hardware_hide = true
        @Published var recording_hide = true
        @Published var gesture_mouse = true
        @Published var gesture_hotbar = true
        @Published var disable_haptics = false
        @Published var slideable_hotbar = false
        @Published var press_duration: Double = 400
        @Published var button_scale: Double = 100
        @Published var mouse_scale: Double = 100
        @Published var mouse_speed: Double = 100
        @Published var virtmouse_enable = false
        @Published var gyroscope_enable = false
        @Published var gyroscope_invert_x_axis = false
        @Published var gyroscope_sensitivity: Double = 100
    }
    @Published var control = Control()
    
    class Java: Codable, ObservableObject {
        @Published var java_args = ""
        @Published var env_variables = ""
        @Published var auto_ram = false
        @Published var allocated_memory: Double = Double(ProcessInfo.processInfo.physicalMemory / 0x100000) * 0.25
    }
    @Published var java = Java()
    
    class Debug: Codable, ObservableObject {
        @Published var debug_skip_wait_jit = false
        @Published var debug_hide_home_indicator = false
        @Published var debug_ipad_ui = false
        @Published var debug_auto_correction = true
    }
    @Published var debug = Debug()
    
    // Internal
    class Miscellaneous: Codable, ObservableObject {
        @Published var isolated = false
        @Published var selected_account = UUID(uuidString: Constants.zeroUUIDString)!
        @Published var latest_version = VersionManifest.Latest()
    }
    @Published var misc = Miscellaneous()
    
    func makeChangesWithoutSaving(closure: () -> Void) {
        Preferences.saveChanges = false
        closure()
        Preferences.saveChanges = true
    }
    
    static func == (l: Preferences, r: Preferences) -> Bool {
        // this is just to make onChange in ContentView work
        return !Preferences.saveChanges
    }
}
