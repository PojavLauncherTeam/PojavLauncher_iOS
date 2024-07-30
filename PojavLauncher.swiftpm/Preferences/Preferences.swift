import UIKit

struct Preferences {
    struct General {
        var check_sha: Bool = true
        var cosmetica: Bool = true
        var debug_logging: Bool = false
        // var appicon: String
    }
    var general = General()
    
    struct Video {
        var renderer: String = "auto"
        var resolution: UInt = 100
        var max_framerate: Bool = true
        var performance_hud: Bool = false
        var fullscreen_airplay: Bool = true
        var silence_other_audio: Bool = false
        var silence_with_switch: Bool = false
    }
    var video = Video()
    
    struct Control {
        var default_ctrl: String = "default.json"
        var control_safe_area: String = "" 
        // Sring(for insets: UIApplication.shared.windows.first.safeAreaInsets)
        var default_gamepad_ctrl: String = "default.json"
        var controller_type: String = "xbox"
        var hardware_hide = true
        var recording_hide = true
        var gesture_mouse = true
        var gesture_hotbar = true
        var disable_haptics = false
        var slideable_hotbar = false
        var press_duration = 400
        var button_scale = 100
        var mouse_scale = 100
        var mouse_speed = 100
        var virtmouse_enable = false
        var gyroscope_enable = false
        var gyroscope_invert_x_axis = false
        var gyroscope_sensitivity = 100
    }
    var control = Control()
    
    struct Java {
        
    }
}
