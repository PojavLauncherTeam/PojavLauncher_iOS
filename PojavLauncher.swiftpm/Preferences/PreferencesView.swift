import SwiftUI
import QuartzCore

struct PreferencesView: View {
    @ObservedObject var preferences: Preferences
    var body: some View {
        Form {
            Section {
                Label("launcher.menu.custom_controls", systemImage: "gamecontroller")
            }
            Section {
                NavigationLink {
                    GeneralView(preferences: preferences)
                } label: {
                    Label("preference.section.general", systemImage: "cube")
                }
                NavigationLink {
                    VideoAndAudioView(preferences: preferences)
                } label: {
                    Label("preference.section.video", systemImage: "video")
                }
                NavigationLink {
                    ControlView(preferences: preferences)
                } label: {
                    Label("preference.section.control", systemImage: "dpad")
                }
                NavigationLink {
                    JavaView(preferences: preferences)
                } label: {
                    Label("preference.section.java", systemImage: "sparkles")
                }
                NavigationLink {
                    DebugView(preferences: preferences)
                } label: {
                    Label("preference.section.debug", systemImage: "ladybug")
                }
            }
            Section {
                Link(destination: URL(string: "https://pojavlauncherteam.github.io/changelogs/IOS.html")!) {
                    Label("News", systemImage: "newspaper")
                }
                Link(destination: URL(string: "https://pojavlauncherteam.github.io")!) {
                    Label("Wiki", systemImage: "book")
                }
                Link(destination: URL(string: "https://github.com/PojavLauncherTeam/PojavLauncher_iOS/issues")!) {
                    Label("Report an issue", systemImage: "ant")
                }
                Button("login.menu.sendlogs", systemImage: "square.and.arrow.up") {
                    let url = GameDirectory.documentsURL.appendingPathComponent("latestlog.old.txt", conformingTo: .plainText)
                    let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                    UIApplication.shared.currentInternalWindow()?.rootViewController?.present(activityVC, animated: true, completion: nil)
                }
            } footer: {
                Text("""
                \(Bundle.main.infoDictionary!["CFBundleName"]!) \(Bundle.main.infoDictionary!["CFBundleShortVersionString"]!) (\(Bundle.main.infoDictionary!["PLBundleBuild"] ?? "?commit/branch"))
                \(UIDevice.current.systemName) \(ProcessInfo.processInfo.operatingSystemVersionString)
                PID: \(ProcessInfo.processInfo.processIdentifier)
                """)
            }
        }
        .navigationTitle("Settings")
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            if UIDevice.current.orientation.isPortrait {
                 self.navigationViewStyle(StackNavigationViewStyle())
            } else {
                self.navigationViewStyle(DoubleColumnNavigationViewStyle())
            }
        }
        GeneralView(preferences: preferences)
    }
    
    private struct GeneralView: View {
        @ObservedObject var preferences: Preferences
        var body: some View {
            Form {
                // Check SHA
                Section {
                    Toggle(isOn: $preferences.general.check_sha) {
                        Label("preference.title.check_sha", systemImage: "cube")
                    }
                } footer: {
                    Text("preference.detail.check_sha")
                }
                // Cosmetica
                Section {
                    Toggle(isOn: $preferences.general.cosmetica) {
                        Label("preference.title.cosmetica", systemImage: "eyeglasses")
                    }
                } footer: {
                    Text("preference.detail.cosmetica")
                }
                // Debug logging
                Section {
                    Toggle(isOn: $preferences.general.debug_logging) {
                        Label("preference.title.debug_logging", systemImage: "doc.badge.gearshape")
                    }
                } footer: {
                    Text("preference.detail.debug_logging")
                }
                // appicon?
                Section {
                    Button(role: .destructive) {
                        
                    } label: {
                        Label("preference.title.reset_settings", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                    Button(role: .destructive) {
                        
                    } label: {
                        Label("preference.title.erase_demo_data", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("preference.section.general")
        }
    }

    private struct VideoAndAudioView: View {
        @ObservedObject var preferences: Preferences
        var body: some View {
            Form {
                // Renderer
                Section {
                    Picker(selection: $preferences.video.renderer) {
                        ForEach(Constants.renderers, id: \.0) {
                            Text(LocalizedStringKey($0.value)).tag($0.key)
                        }
                    } label: {
                        Label("preference.title.renderer", systemImage: "cpu")
                    }
                } footer: {
                    Text("preference.detail.renderer")
                }
                // Resolution
                Section {
                    DisclosureGroup {
                        Slider(value: $preferences.video.resolution, in: 25...150, step: 1, minimumValueLabel: Text("25"), maximumValueLabel: Text("150")) {}
                    } label: {
                        Label("preference.title.resolution", systemImage: "viewfinder")
                            .badge("\(Int(preferences.video.resolution))%")
                    }
                } footer: {
                    Text("preference.detail.resolution")
                }
                // Max framerate
                Section {
                    Toggle(isOn: $preferences.video.max_framerate) {
                        Label("preference.title.max_framerate", systemImage: "timelapse")
                    }
                    .disabled(UIScreen.main.maximumFramesPerSecond <= 60)
                } footer: {
                    Text("preference.detail.max_framerate")
                }
                // Performance HUD
                Section {
                    Toggle(isOn: $preferences.video.performance_hud) {
                        Label("preference.title.performance_hud", systemImage: "waveform.path.ecg")
                    }
                    .disabled(!CAMetalLayer.instancesRespond(to: Selector("developerHUDProperties")))
                } footer: {
                    Text("preference.detail.performance_hud")
                }
                // Fullscreen AirPlay
                Section {
                    Toggle(isOn: $preferences.video.fullscreen_airplay) {
                        Label("preference.title.fullscreen_airplay", systemImage: "airplayvideo")
                    }
                } footer: {
                    Text("preference.detail.fullscreen_airplay")
                }
                // Silence other audio
                Section {
                    Toggle(isOn: $preferences.video.silence_other_audio) {
                        Label("preference.title.silence_other_audio", systemImage: "speaker.slash")
                    }
                } footer: {
                    Text("preference.detail.silence_other_audio")
                }
                // Silence with switch
                Section {
                    Toggle(isOn: $preferences.video.silence_with_switch) {
                        Label("preference.title.silence_with_switch", systemImage: "speaker.zzz")
                    }
                } footer: {
                    Text("preference.detail.silence_with_switch")
                }
            }
            .navigationTitle("preference.section.video")
        }
    }
    
    private struct ControlView: View {
        @ObservedObject var preferences: Preferences
        var body: some View {
            Form {
                // Gamepad remapper
                NavigationLink {
                    Text("Game controller")
                } label: {
                    Label("preference.title.default_gamepad_ctrl", systemImage: "hammer")
                }
                Section {
                    // Recording hide
                    Toggle(isOn: $preferences.control.hardware_hide) {
                        Label("preference.title.hardware_hide", systemImage: "eye.slash")
                    }
                    // Recording hide
                    Toggle(isOn: $preferences.control.recording_hide) {
                        Label("preference.title.recording_hide", systemImage: "rectangle.dashed.badge.record")
                    }
                    DisclosureGroup {
                        Slider(value: $preferences.control.button_scale, in: 50...500, step: 1, minimumValueLabel: Text("50"), maximumValueLabel: Text("500")) {}
                    } label: {
                        Label("preference.title.button_scale", systemImage: "aspectratio")
                            .badge("\(Int(preferences.control.button_scale))%")
                    }
                } header: {
                    Text("preference.section.control.appearance")
                }
                // TODO: allow deeper gesture customizations
                Section {
                    // Mouse gesture
                    Toggle(isOn: $preferences.control.gesture_mouse) {
                        Label("preference.title.gesture_mouse", systemImage: "cursorarrow.click")
                    }
                    // Hotbar gesture
                    Toggle(isOn: $preferences.control.gesture_hotbar) {
                        Label("preference.title.gesture_hotbar", systemImage: "squares.below.rectangle")
                    }
                    // Slidable hotbar
                    Toggle(isOn: $preferences.control.slideable_hotbar) {
                        Label("preference.title.slideable_hotbar", systemImage: "slider.horizontal.below.rectangle")
                    }
                    // Disable haptics
                    Toggle(isOn: $preferences.control.disable_haptics) {
                        Label("preference.title.disable_haptics", systemImage: "wave.3.left")
                    }
                } header: {
                    Text("preference.section.control.gesture")
                }
                Section {
                    // Virtual mouse
                    Toggle(isOn: $preferences.control.virtmouse_enable) {
                        Label("preference.title.virtmouse_enable", systemImage: "cursorarrow.rays")
                    }
                    // Mouse scale
                    DisclosureGroup {
                        Slider(value: $preferences.control.mouse_scale, in: 25...300, step: 1, minimumValueLabel: Text("25"), maximumValueLabel: Text("300")) {}
                    } label: {
                        Label("preference.title.mouse_scale", systemImage: "arrow.up.left.and.arrow.down.right.circle")
                            .badge("\(Int(preferences.control.mouse_scale))%")
                    }
                    // Mouse speed
                    DisclosureGroup {
                        Slider(value: $preferences.control.mouse_speed, in: 25...300, step: 1, minimumValueLabel: Text("25"), maximumValueLabel: Text("300")) {}
                    } label: {
                        Label("preference.title.mouse_speed", systemImage: "cursorarrow.motionlines")
                            .badge("\(Int(preferences.control.mouse_speed))%")
                    }
                    // Press duration
                    DisclosureGroup {
                        Slider(value: $preferences.control.press_duration, in: 100...1000, step: 1, minimumValueLabel: Text("100"), maximumValueLabel: Text("1000")) {}
                    } label: {
                        Label("preference.title.press_duration", systemImage: "cursorarrow.click.badge.clock")
                            .badge("\(UInt( preferences.control.press_duration))ms")
                    }
                } header: {
                    Text("preference.section.control.mouse")
                }
                Section {
                    // Gyroscope
                    Toggle(isOn: $preferences.control.gyroscope_enable) {
                        Label("preference.title.gyroscope_enable", systemImage: "gyroscope")
                    }
                    // Gyroscope invert X axis
                    Toggle(isOn: $preferences.control.gyroscope_invert_x_axis) {
                        Label("preference.title.gyroscope_invert_x_axis", systemImage: "arrow.left.and.right")
                    }
                    // Gyroscope sensitivity
                    DisclosureGroup {
                        Slider(value: $preferences.control.gyroscope_sensitivity, in: 50...300, step: 1, minimumValueLabel: Text("50"), maximumValueLabel: Text("300")) {}
                    } label: {
                        Label("preference.title.gyroscope_sensitivity", systemImage: "move.3d")
                            .badge("\(Int(preferences.control.gyroscope_sensitivity))%")
                    }
                } header: {
                    Text("preference.section.control.gyroscope")
                }
            }
            .navigationTitle("preference.section.control")
        }
    }
    
    private struct JavaView: View {
        @ObservedObject var preferences: Preferences
        var body: some View {
            Form {
                // Manage runtimes
                Section {
                    NavigationLink {
                        Text("Manage runtimes")
                    } label: {
                        Label("preference.title.manage_runtime", systemImage: "cube")
                    }
                }
                // Java args
                // NOTE: allow line breaks, later we'll filter them out
                DisclosureGroup {
                    TextEditor(text: $preferences.java.java_args)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                } label: {
                    Label("preference.title.java_args", systemImage: "slider.vertical.3")
                }
                // Environment variables
                // NOTE: allow line breaks, later we'll filter them out
                DisclosureGroup {
                    TextEditor(text: $preferences.java.env_variables)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                } label: {
                    Label("preference.title.env_variables", systemImage: "terminal")
                }
                // Memory allocation
                Section {
                    Toggle(isOn: $preferences.java.auto_ram) {
                        Label("preference.title.auto_ram", systemImage: "slider.horizontal.3")
                    }
                    DisclosureGroup {
                        Slider(value: $preferences.java.allocated_memory, in: 250...Constants.maxMemoryLimit, step: 1, minimumValueLabel: Text("250"), maximumValueLabel: Text("\(UInt(Constants.maxMemoryLimit))")) {}
                            .disabled(preferences.java.auto_ram)
                    } label: {
                        Label("preference.title.allocated_memory", systemImage: "memorychip")
                            .badge(Int(preferences.java.allocated_memory))
                    }
                } footer: {
                    Text("preference.detail.allocated_memory")
                }
            }
            .navigationTitle("preference.section.java")
        }
    }
    
    private struct DebugView: View {
        @ObservedObject var preferences: Preferences
        var body: some View {
            Form {
                // Skip waiting for JIT
                Section {
                    Toggle(isOn: $preferences.debug.debug_skip_wait_jit) {
                        Label("preference.title.debug_skip_wait_jit", systemImage: "forward")
                    }
                } footer: {
                    Text("preference.detail.debug_skip_wait_jit")
                }
                // Hide home indicator
                Section {
                    Toggle(isOn: $preferences.debug.debug_hide_home_indicator) {
                        Label("preference.title.debug_hide_home_indicator", systemImage: "iphone.and.arrow.forward")
                    }
                    .disabled(UIApplication.shared.currentInternalWindow()?.safeAreaInsets.bottom == 0)
                } footer: {
                    Text("preference.detail.debug_hide_home_indicator")
                }
                // iPadOS UI
                Section {
                    Toggle(isOn: $preferences.debug.debug_ipad_ui) {
                        Label("preference.title.debug_ipad_ui", systemImage: "ipad")
                    }
                } footer: {
                    Text("preference.detail.debug_ipad_ui")
                }
                // Auto correction
                Section {
                    Toggle(isOn: $preferences.debug.debug_auto_correction) {
                        Label("preference.title.debug_auto_correction", systemImage: "textformat.abc.dottedunderline")
                    }
                } footer: {
                    Text("preference.detail.debug_auto_correction")
                }
            }
            .navigationTitle("preference.section.debug")
        }
    }
}
