import Alamofire
import OrderedCollections
import SwiftUI

struct VersionPickerView: View {
    @EnvironmentObject var preferences: Preferences
    @Binding var selection: String
    @State private var manifest: VersionManifest?
    @State private var type: VersionType = .installed
    
    enum LatestVersion: String {
        case release = "latest-release"
        case snapshot = "latest-snapshot"
    }
    
    var body: some View {
        Picker("Version type", selection: $type) {
            ForEach(VersionType.allCases, id: \.self) { value in
                Text(value.name).tag(value.rawValue)
            }
        }
        Picker("Version", selection: $selection) {
            if self.type == .installed {
                let installedVersions = Array(listInstalledVersions())
                ForEach(installedVersions, id: \.self) { version in
                    Text(version)
                }
            } else if manifest == nil {
                Text("Loading versions").disabled(true)
            } else {
                if self.type == .release {
                    Text("Latest release")
                        .tag(LatestVersion.release.rawValue)
                } else if self.type == .snapshot {
                    Text("Latest snapshot")
                        .tag(LatestVersion.snapshot.rawValue)
                }
                ForEach(manifest!.versions, id: \.id) { version in
                    if version.type == self.type {
                        Text(version.id)
                    }
                }
            }
        }
        #if os(tvOS)
        .pickerStyle(.navigationLink)
        #else
        .pickerStyle(.wheel)
        #endif
        .onAppear {
            guard self.manifest == nil else { return }
            AF.request("https://piston-meta.mojang.com/mc/game/version_manifest_v2.json")
                .cacheResponse(using: .cache)
                .responseDecodable(of: VersionManifest.self) { response in
                    switch response.result {
                    case .success(let value):
                        preferences.misc.latest_version = value.latest
                        self.manifest = value
                        if self.selection == LatestVersion.release.rawValue {
                            self.type = .release
                        } else if self.selection == LatestVersion.snapshot.rawValue {
                            self.type = .snapshot
                        } else if let matchingVersion = (self.manifest?.versions.filter { $0.id == self.selection })?.first {
                            self.type = matchingVersion.type
                        }
                    case .failure(let error):
                        print(error)
                    }
                }
        }
    }
    
    func listInstalledVersions() -> OrderedSet<String> {
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: GameDirectory.versionsPath(of: preferences.general.game_directory!), includingPropertiesForKeys: nil)
            return OrderedSet(directoryContents.filter {
                $0.hasDirectoryPath
            }.map {
                $0.lastPathComponent
            })
        } catch {
            debugPrint(error)
            return []
        }
    }
}
