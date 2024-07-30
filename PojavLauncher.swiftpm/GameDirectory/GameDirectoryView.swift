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
    @State private var directories: OrderedSet<String> = listInstancesDir()
    @State private var showInitialProfilesOnce = false
    @State private var showInitialProfilesView = false
    @State private var showCreateDirectoryInput = false
    @State private var showDeleteAlert = false
    @State private var dirToProcess = ""
    var body: some View {
        // Hidden navigation link
        NavigationLink(destination: ProfilesView(), isActive: $showInitialProfilesView) {
            EmptyView()
        }
        // Game directories
        List {
            ForEach (directories, id: \.self) { directory in
                NavigationLink {
                    ProfilesView()
                } label: {
                    GameDirectoryRow(directory: directory)
                }
                .swipeActions(allowsFullSwipe: true) {
                    Button("Delete") {
                        dirToProcess = directory
                        showDeleteAlert.toggle()
                    }.tint(.red)
                }.id(directory)
            }
        }
        .confirmationDialog("preference.title.confirm", isPresented: $showDeleteAlert, titleVisibility: .visible) {
            Button("OK", role: .destructive) {
                GameDirectory.removeDirectory(dirToProcess)
                withAnimation {
                    directories.remove(dirToProcess)
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
        .onAppear {
            if !showInitialProfilesOnce {
                showInitialProfilesOnce = true
                showInitialProfilesView = true
            }
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
