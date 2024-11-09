import SwiftUI
import Alamofire

struct ProfilesView: View {
    @ObservedObject var launcherProfiles: LauncherProfiles
    var directory: String
    @State private var selectedProfile: String?
    @State private var isolateSettings = false
    
    init(directory: String) {
        self.directory = directory
        do {
            let jsonData = try Data(contentsOf: GameDirectory.lpJsonPath(of: directory))
            self.launcherProfiles = try! JSONDecoder().decode(LauncherProfiles.self, from: jsonData)
        } catch {
            print("Unexpected error: \(error).")
            self.launcherProfiles =  LauncherProfiles()
        }
    }
    
    var body: some View {
        Form {
            Section {
                Label("launcher.menu.execute_jar", systemImage: "terminal")
            }
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
                List(selection: $selectedProfile) {
                    let keys = Array(launcherProfiles.profiles.keys)
                    ForEach(keys, id: \.self) { key in
                        ProfileRow(profile: self.launcherProfiles.profiles[key]!, selection: $selectedProfile, tag: key)
                    }
                    .onDelete { offsets in
                        self.launcherProfiles.profiles.removeValue(forKey: keys[offsets.first!])
                        saveChanges()
                    }
                }
            } header: {
                Text("profile.section.profiles")
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add", systemImage: "plus") {
                    withAnimation {
                        let key = UUID(.timeOrdered()).uuidString
                        launcherProfiles.profiles[key] = Profile()
                        selectedProfile = key
                        saveChanges()
                    }
                }
            }
        }
        .onAppear {
            saveChanges()
        }
        .navigationTitle(directory)
    }
    
    func saveChanges() {
        if let jsonData = try? JSONEncoder().encode(self.launcherProfiles) {
            do {
                try jsonData.write(to: GameDirectory.lpJsonPath(of: directory))
            } catch {
                print("Failed to write launcher_profiles.json: \(error.localizedDescription)")
            }
        }
    }
}
