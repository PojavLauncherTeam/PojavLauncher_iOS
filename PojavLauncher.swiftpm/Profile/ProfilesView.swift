import SwiftUI

struct ProfilesView: View {
    @State private var selectedProfileIdx: Int?
    @State private var isolateSettings = false
    @State private var launcherProfiles = LauncherProfiles()
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    Toggle(isOn: $isolateSettings) {
                        Label("Isolate settings", systemImage: "folder.badge.gearshape")
                    }
                }
            } header: {
                Text("Game instance settings")
            } footer: {
                Text("When enabled, changes in the launcher settings will only be available to this instance.")
            }
            Section {
                ForEach (0..<launcherProfiles.profiles.count, id: \.self) { i in
                    ProfileRow(profile: $launcherProfiles.profiles[i])
                }
                 .onDelete(perform: delete)
            } header: {
                Text("profile.section.profiles")
            }
        }
        .navigationTitle("Profiles")
    }
    
    func delete(at offsets: IndexSet) {
        // delete the objects here
    }
}
