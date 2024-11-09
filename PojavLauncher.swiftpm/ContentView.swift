import Alamofire
import SwiftUI
import UniqueID

struct ContentView: View {
    @StateObject var state = SharedState()
    @ObservedObject var preferences = (try? PropertyListDecoder().decode(Preferences.self, from: Data(contentsOf: GameDirectory.rootPrefsURL))) ?? Preferences()
    @State private var showAccountView = false
    @State var preferencesUpdateItem: DispatchWorkItem?
    
    var accountBtn: some View {
        Button {
            showAccountView.toggle()
        } label: {
            ZStack {
                let account = preferences.accounts[preferences.misc.selected_account]
                HTTPImage(url: account?.profilePicURL, defaultImageName: "DefaultAccount")
                    .opacity(state.isMSALoggingIn ? 0.5 : 1)
                if state.isMSALoggingIn {
                    ProgressView()
                }
            }
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
            let view = AccountView(showModal: $showAccountView).onAuthenticate { code in
                var account = Account()
                account.tmpAuthcode = code
                account.type = .msaAuthenticating
                preferences.makeChangesWithoutSaving {
                    preferences.accounts[account.uniqueIdentifier] = account
                }
                preferences.misc.selected_account = account.uniqueIdentifier
                authenticate(refresh: false)
            }
            if #available(iOS 16.0, *) {
                view.presentationDetents([.medium, .large])
            } else {
                view
            }
        }
        .environmentObject(state)
        .environmentObject(preferences)
        .onChange(of: preferences) { _ in
            preferencesUpdateItem?.cancel()
            let item = DispatchWorkItem {
                try! PropertyListEncoder().encode(preferences).write(to: GameDirectory.rootPrefsURL)
            }
            preferencesUpdateItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: item)
        }
        .onChange(of: preferences.misc.selected_account) { _ in
            authenticateIfNecessary()
        }
        .onAppear {
            authenticateIfNecessary()
        }
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
    
    func authenticateIfNecessary() {
        if let account = preferences.accounts[preferences.misc.selected_account],
           UInt64(Date().timeIntervalSince1970) > account.expiresAt,
           !state.isMSALoggingIn {
            switch account.type {
            case .msaFailedAuth, .msaDemo, .msa:
                authenticate(refresh: true)
            default:
                break
            }
        }
    }
    
    func authenticate(refresh: Bool) {
        state.isMSALoggingIn = true
        Task {
            var account = preferences.accounts[preferences.misc.selected_account]!
            preferences.makeChangesWithoutSaving {
                account.type = .msaAuthenticating
                preferences.accounts[account.uniqueIdentifier] = account
            }
            guard let authcode = refresh ? account.tokenData.refreshToken : account.tmpAuthcode else { return }
            do {
                state.currentAuthStep = "login.msa.progress.acquireAccessToken"
                let tokens = try await MicrosoftAuth.acquireAccessToken(authcode: authcode, refresh: refresh)
                account.tmpAuthcode = nil
                
                state.currentAuthStep = "login.msa.progress.acquireXBLToken"
                let xblToken = try await MicrosoftAuth.acquireXBLToken(accessToken: tokens.accessToken)
                
                state.currentAuthStep = "login.msa.progress.acquireXSTS"
                let xstsXboxToken = try await MicrosoftAuth.acquireXSTS(for: "http://xboxlive.com", xblToken: xblToken)
                let xstsMCToken = try await MicrosoftAuth.acquireXSTS(for: "rp://api.minecraftservices.com/", xblToken: xblToken)
                
                state.currentAuthStep = "login.msa.progress.acquireXboxProfile"
                let xboxProfile = try await MicrosoftAuth.acquireXboxProfile(xblUhs: xstsXboxToken.uhs, xblXsts: xstsXboxToken.xsts)
                
                state.currentAuthStep = "login.msa.progress.acquireMCToken"
                let mcToken = try await MicrosoftAuth.acquireMinecraftToken(xblUhs: xstsMCToken.uhs, xblXsts: xstsMCToken.xsts)
                
                state.currentAuthStep = "login.msa.progress.checkMCProfile"
                let mcProfile = try await MicrosoftAuth.checkMinecraftProfile(accessToken: mcToken)
                let profilePicURL = mcProfile.name != nil ? "https://mc-heads.net/head/\(mcProfile.id!)/120" : xboxProfile.profilePicURL
                
                state.currentAuthStep = ""
                account.type = (mcProfile.name != nil) ? .msa : .msaDemo
                account.xboxGamertag = xboxProfile.xboxGamertag
                account.username = mcProfile.name ?? xboxProfile.xboxGamertag
                account.expiresAt = UInt64(Date().timeIntervalSince1970) + 86400
                account.xuid = xstsXboxToken.uhs
                account.profileId = UUID(uuidString: mcProfile.id!)!
                account.profilePicURL = profilePicURL
                account.tokenData = (accessToken: mcToken, refreshToken: tokens.refreshToken)
                preferences.accounts.removeValue(forKey: account.uniqueIdentifier)
                preferences.accounts[account.uniqueIdentifier] = account
            } catch {
                print("Error: \(error)")
                account.type = .msaFailedAuth
                if refresh {
                    preferences.accounts[account.uniqueIdentifier] = account
                } else {
                    preferences.accounts.removeValue(forKey: account.uniqueIdentifier)
                }
            }
            state.isMSALoggingIn = false
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
