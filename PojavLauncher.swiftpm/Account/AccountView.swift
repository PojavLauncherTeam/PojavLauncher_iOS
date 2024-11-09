import BetterSafariView
import SwiftUI

struct AccountRow: View {
    @EnvironmentObject var state: SharedState
    @EnvironmentObject var preferences: Preferences
    @State var accountID: UUID
    var body: some View {
        HStack {
            let account = preferences.accounts[accountID] ?? Account()
            let isSelected = preferences.misc.selected_account == accountID
            HTTPImage(url: account.profilePicURL, defaultImageName: "DefaultAccount")
            VStack(alignment: .leading) {
                let isAuthenticating = account.type == .msaAuthenticating
                let isDemo = account.type == .msaDemo
                let isLocal = account.type == .local
                let username = isDemo ? account.xboxGamertag : account.username
                Text(username.isEmpty ? String(localized: "login.option.add") : username)
                if isAuthenticating {
                    Text(LocalizedStringKey(state.currentAuthStep))
                        .font(Font.footnote)
                } else {
                    Text(
                        isDemo ? String(localized: "login.option.demo") :
                            isLocal ? String(localized: "login.option.local") : account.xboxGamertag).font(Font.footnote)
                }
            }
            Spacer()
            if isSelected && state.isMSALoggingIn {
                ProgressView()
            } else {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .renderingMode(.original)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 30, height: 30)
                    .opacity(state.isMSALoggingIn ? 0.5 : 1)
            }
        }
    }
}

struct AccountView: View {
    @EnvironmentObject var state: SharedState
    @EnvironmentObject var preferences: Preferences
    @Binding var showModal: Bool
    @State private var showCreateLocalAccountAlert = false
    @State private var showCreateLocalAccountInvalidUsernameError = false
    @State private var showMicrosoftAuthSession = false
    @State private var username: String = ""
    var onAuthenticate = { (code: String) -> Void in
        print("MSA: onAuthenticate is not assigned")
    }
    
    var body: some View {
        NavigationView {
            List {
                let accounts = Array(preferences.accounts.keys)
                // FIXME: sorting by username
                // .sorted { $0.value.username < $1.value.username }.lazy.map { $0.key }
                ForEach(accounts, id: \.self) { accountID in
                    AccountRow(accountID: accountID).onTapGesture {
                        preferences.misc.selected_account = accountID
                        // FIXME: it doesn't update without this line
                        preferences.misc = preferences.misc
                    }
                }
                .onDelete { offsets in
                    preferences.accounts.removeValue(forKey: accounts[offsets.first!])
                }
                .disabled(state.isMSALoggingIn)
            }
            .navigationTitle("Accounts")
            .toolbar {
                Menu("Add", systemImage: "plus") {
                    Button("Microsoft account") {
                        showMicrosoftAuthSession = true
                    }
                    Button("Local account") {
                        username = ""
                        showCreateLocalAccountInvalidUsernameError = false
                        showCreateLocalAccountAlert = true
                    }
                }
                Button("Done") {
                    showModal.toggle()
                }
            }
        }
        .alert("Sign in", isPresented: $showCreateLocalAccountAlert) {
            TextField("Username", text: $username)
            Button("OK") {
                guard username.count >= 3 && username.count <= 16 else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showCreateLocalAccountInvalidUsernameError = true
                        showCreateLocalAccountAlert = true
                    }
                    return
                }
                let account = Account(type: .local, xboxGamertag: "", username: username, expiresAt: 0, xuid: "", profileId: .init(), profilePicURL: "")
                username = ""
                preferences.accounts[account.uniqueIdentifier] = account
                preferences.misc.selected_account = account.uniqueIdentifier
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(showCreateLocalAccountInvalidUsernameError ? "login.error.username.outOfRange" : "Local account will not be able to download game assets.")
        }
        .webAuthenticationSession(isPresented: $showMicrosoftAuthSession) {
            WebAuthenticationSession(
                url: Constants.msaAuthURL,
                callbackURLScheme: Constants.msaAuthCallbackURLScheme
            ) { callbackURL, error in
                guard let callbackURL,
                      let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                      let queryItems = components.queryItems
                else { return }
                let items = queryItems.reduce(into: [String : String]()) {
                    $0[$1.name] = $1.value
                }
                
                if let code = items["code"] {
                    onAuthenticate(code)
                } else if let error = items["error"], let errorDescription = items["error_description"] {
                    guard error != "access_denied" else { return }
                    print("Error \(error): \(errorDescription)")
                }
            }
            .prefersEphemeralWebBrowserSession(true)
        }
    }
    
    func onAuthenticate(_ callback: @escaping (_ code: String) -> ()) -> some View { 
        AccountView(showModal: $showModal, onAuthenticate: callback)
    }
}
