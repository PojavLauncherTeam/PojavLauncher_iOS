import SwiftUI
import UniqueID

struct ProfileEditView: View {
    @ObservedObject var profile: Profile
    @State private var showImageFilePicker = false
    @State private var showImageGalleryPicker = false
    @State private var showCustomIconInput = false
    @State private var expandItemGameDir = false
    @State private var iconToSave: String = ""
    @State private var newImage: UIImage = UIImage()
    
    var body: some View {
        Form {
            HStack {
                Menu {
                    Button("Photo Library", systemImage: "photo.on.rectangle") {
                        showImageGalleryPicker.toggle()
                    }
                    Button("Choose File", systemImage: "folder") {
                        showImageFilePicker.toggle()
                    }
                    Button("Custom URL", systemImage: "link") {
                        showCustomIconInput.toggle()
                    }
                } label: {
                    HTTPImage(url: profile.icon, defaultImageName: "DefaultProfile")
                }
                TextField("preference.profile.title.name", text: $profile.name)
            }.listRowInsets(EdgeInsets(top: 12, leading: 15, bottom: 12, trailing: 15))
            Section {
                DisclosureGroup {
                    VersionPickerView(selection: $profile.lastVersionId)
                } label: {
                    Label("preference.profile.title.version", systemImage: "archivebox")
                        .badge(profile.lastVersionId)
                }
                DisclosureGroup(isExpanded: $expandItemGameDir) {
                    TextField(". -> instances/<current>", text: $profile.gameDir ?? "")
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                } label: {
                    Label("preference.title.game_directory", systemImage: "folder")
                        .badge(expandItemGameDir ? nil : profile.gameDir)
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
        .sheet(isPresented: $showImageGalleryPicker) {
            ImagePicker(sourceType: .photoLibrary, selectedImage: $newImage)
        }
        .fileImporter(isPresented: $showImageFilePicker, allowedContentTypes: [.image], onCompletion: { result in
            
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
