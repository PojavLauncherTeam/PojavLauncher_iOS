import SwiftUI
import Alamofire

struct ContentView: View {
    @State private var showAccountView = false
    var accountBtn: some View {
        Button("[AccIcon]") {
            showAccountView.toggle()
        }
        .sheet(isPresented: $showAccountView) {
            if #available(iOS 16.0, *) {
                AccountView(showModal: $showAccountView)
                    .presentationDetents([.medium, .large])
            } else {
                AccountView(showModal: $showAccountView)
            }
        }
    }
    var body: some View {
        TabView {
            if #available(iOS 16, *) {
                NavigationStack {
                    GameDirectoryView()
                        .toolbar { accountBtn }
                }
                .tabItem {
                    Label("Profiles", systemImage: "folder")
                }
            } else {
                NavigationView {
                    GameDirectoryView()
                        .toolbar { accountBtn }
                }
                .navigationViewStyle(.stack)
                .tabItem {
                    Label("Profiles", systemImage: "folder")
                }
            }
            NavigationView {
                PreferencesView()
                    .toolbar {
                        accountBtn
                    }
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
