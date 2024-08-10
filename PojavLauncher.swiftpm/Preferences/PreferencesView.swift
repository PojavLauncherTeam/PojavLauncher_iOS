import SwiftUI

struct PreferencesView: View {
    var body: some View {
        Form {
            Section {
                Label("launcher.menu.custom_controls", systemImage: "gamecontroller")
            }
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
                Label("login.menu.sendlogs", systemImage: "square.and.arrow.up")
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
