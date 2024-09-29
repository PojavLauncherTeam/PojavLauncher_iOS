import SwiftUI
import Alamofire

struct ContentView: View {
    @StateObject var preferences = Preferences()
    @State private var showAccountView = false
    var accountBtn: some View {
        Button("[AccIcon]") {
            showAccountView.toggle()
        }
    }
    var body: some View {
        TabView {
            NavigationView {
                GameDirectoryView()
                    .toolbar { accountBtn }
                Text("Select a game directory to view profiles")
            }
            .tabItem {
                Label("Profiles", systemImage: "folder")
            }
            NavigationView {
                PreferencesView()
                    .toolbar { accountBtn }
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        .onAppear {
            UITextField.appearance().clearButtonMode = .whileEditing
        }
        .sheet(isPresented: $showAccountView) {
            if #available(iOS 16.0, *) {
                AccountView(showModal: $showAccountView)
                    .presentationDetents([.medium, .large])
            } else {
                AccountView(showModal: $showAccountView)
            }
        }
        .environmentObject(preferences)
        /*
        .onAppear {
            // DEBUG: scale till we get iPadOS sidebar
            let scale = 1.5
            let window = UIApplication.shared.currentInternalWindow()!
            var bounds = UIScreen.main.bounds
            bounds.size.width *= scale
            bounds.size.height *= scale
            window.bounds = bounds
            window.transform = CGAffineTransformMakeScale(1.0/scale, 1.0/scale)
        }
        */
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
