import SwiftUI

struct PreferencesView: View {
    var body: some View {
        Form {
            Section {
                NavigationLink {
                    Text("General")
                } label: {
                    Label("preference.section.general", systemImage: "cube")
                }
                NavigationLink {
                    Text("Video and Audio")
                } label: {
                    Label("preference.section.video", systemImage: "video")
                }
                NavigationLink {
                    Text("control")
                } label: {
                    Label("preference.section.control", systemImage: "gamecontroller")
                }
                NavigationLink {
                    Text("java")
                } label: {
                    Label("preference.section.java", systemImage: "sparkles")
                }
                NavigationLink {
                    Text("debug")
                } label: {
                    Label("preference.section.debug", systemImage: "ladybug")
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
    }
}
