import SwiftUI
import OrderedCollections

struct GameDirectoryRow: View {
    @State var directory: String
    var body: some View {
        VStack(alignment: .leading) {
            Text(directory)
            Text("[directory size]").font(Font.footnote)
        }
    }
}

struct GameDirectoryView: View {
    @ObservedObject var preferences: Preferences
    @State private var directories: OrderedSet<String> = listInstancesDir()
    @State private var showCreateDirectoryInput = false
    @State private var showDeleteAlert = false
    @State private var dirToProcess = ""
    var body: some View {
        // Game directories
        List(directories, id: \.self, selection: $preferences.general.game_directory) { directory in
            HStack {
                NavigationLink(tag: directory, selection: $preferences.general.game_directory) {
                    ProfilesView(directory: directory)
                } label: {
                    GameDirectoryRow(directory: directory)
                }
            }
            .swipeActions(allowsFullSwipe: true) {
                Button("Delete") {
                    dirToProcess = directory
                    showDeleteAlert.toggle()
                }.tint(.red)
            }.id(directory)
        }
        .confirmationDialog("preference.title.confirm", isPresented: $showDeleteAlert, titleVisibility: .visible) {
            Button("OK", role: .destructive) {
                GameDirectory.removeDirectory(dirToProcess)
                // Always keep the default directory
                if dirToProcess != "default" {
                    withAnimation {
                        directories.remove(dirToProcess)
                    }
                }
                // Reset to default if the user deletes current directory
                if dirToProcess == preferences.general.game_directory {
                    preferences.general.game_directory = "default"
                }
            }
        } message: {
            Text("preference.title.confirm.delete_game_directory \(dirToProcess)")
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add", systemImage: "plus") {
                    showCreateDirectoryInput.toggle()
                }
            }
        }
        .alert("preference.multidir.add_directory", isPresented: $showCreateDirectoryInput) {
            TextField("Directory name", text: $dirToProcess)
            Button("OK") {
                if dirToProcess.isEmpty { return }
                if directories.contains(dirToProcess) {
                    // TODO
                } else {
                    GameDirectory.createDirectory(dirToProcess)
                    withAnimation(.spring()) {
                        directories.append(dirToProcess)
                        dirToProcess = ""
                    }
                    return
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .navigationTitle("Game directory")
    }
    
    func delete(at offsets: IndexSet) {
        // delete the objects here
    }
}

func listInstancesDir() -> OrderedSet<String> {
    do {
        let directoryContents = try FileManager.default.contentsOfDirectory(at: GameDirectory.instancesURL, includingPropertiesForKeys: nil)
        return OrderedSet(directoryContents.filter {
            $0.hasDirectoryPath
        }.map {
            $0.lastPathComponent
        })
    } catch {
        print(error)
        return []
    }
}
