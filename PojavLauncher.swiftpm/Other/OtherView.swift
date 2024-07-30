import SwiftUI

struct OtherView: View {
    var body: some View {
        Form {
            Section {
                Label("launcher.menu.execute_jar", systemImage: "terminal")
                Label("login.menu.sendlogs", systemImage: "square.and.arrow.up")
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
            } header: {
                Text("Links")
            }
        }
        .navigationTitle("Other")
    }
}
