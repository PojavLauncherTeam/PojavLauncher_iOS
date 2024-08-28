import SwiftUI
import UniqueID

struct ProfileEditView: View {
    @ObservedObject var profile: Profile
    @State private var showFilePicker = false
    @State private var showImagePicker = false
    @State private var showCustomIconInput = false
    @State private var showGameDirPicker = false
    @State private var iconToSave: String = ""
    @State private var newImage: UIImage = UIImage()
    
    var body: some View {
        Form {
            HStack {
                Menu {
                    Button("Photo Library", systemImage: "photo.on.rectangle") {
                        showImagePicker.toggle()
                    }
                    Button("Choose File", systemImage: "folder") {
                        showFilePicker.toggle()
                    }
                    Button("Custom URL", systemImage: "link") {
                        showCustomIconInput.toggle()
                    }
                } label: {
                    ProfileImage(url: profile.icon)
                }
                TextField("preference.profile.title.name", text: $profile.name)
            }.listRowInsets(EdgeInsets(top: 12, leading: 15, bottom: 12, trailing: 15))
            Section {
                NavigationLink {
                    Text("WIP")
                } label: {
                    Label("preference.profile.title.version", systemImage: "archivebox")
                        .badge(profile.lastVersionId)
                }
                Button {
                    showGameDirPicker.toggle()
                } label: {
                    NavigationLink {
                        Text("WIP")
                    } label: {
                        Label("preference.title.game_directory", systemImage: "folder")
                            .badge(profile.gameDir)
                    }
                    .tint(.primary)
                }
            }
            Section {
                Picker(selection: $profile.renderer ?? "") {
                    Text("(default)").tag("")
                    ForEach(Constants.renderers, id: \.0) {
                        Text(LocalizedStringKey($0.value)).tag($0.key)
                    }
                } label: {
                    Label("preference.title.renderer", systemImage: "cpu")
                }
            }
            Section {
                Picker(selection: $profile.defaultTouchCtrl ?? "") {
                    Text("(default)").tag("")
                } label: {
                    Label("preference.profile.title.default_touch_control", systemImage: "hand.tap")
                }
                Picker(selection: $profile.defaultGamepadCtrl ?? "") {
                    Text("(default)").tag("")
                } label: {
                    Label("preference.profile.title.default_gamepad_control", systemImage: "gamecontroller")
                }
            }
            Section {
                Picker(selection: $profile.javaVersion ?? "") {
                    Text("(default)").tag("")
                    // TODO: pull these from available versions
                    Text("8").tag("8")
                    Text("17").tag("17")
                    Text("21").tag("21")
                } label: {
                    Label("preference.manage_runtime.header.default", systemImage: "cube")
                }
                DisclosureGroup {
                    TextEditor(text: $profile.javaArgs ?? "")
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                } label: {
                    Label("preference.title.java_args", systemImage: "slider.vertical.3")
                }
            }
        }
        .navigationTitle("Edit profile")
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: .photoLibrary, selectedImage: $newImage)
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.image], onCompletion: { result in
            
        })
        .alert("Custom icon URL", isPresented: $showCustomIconInput) {
            TextField("URL", text: $iconToSave)
            Button("OK") {
                profile.icon = iconToSave
            }
            Button("Cancel", role: .cancel) {
                iconToSave = profile.icon ?? ""
            }
        }
        .toolbar {
            Button("Play", systemImage: "play.fill") {
                // TODO
            }
        }
        .onAppear {
            self.iconToSave = profile.icon ?? ""
        }
    }
}
