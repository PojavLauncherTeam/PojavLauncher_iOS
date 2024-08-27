import SwiftUI

struct AccountRow: View {
    @State var account: Account
    var body: some View {
        HStack {
            if account.profilePicURL.isEmpty {
                Image("DefaultAccount")
            } else {
                AsyncImage(url: URL(string: account.profilePicURL)) { phase in
                    switch phase {
                    case .failure:
                        Image("DefaultAccount")
                    case .success(let image):
                        image
                            .resizable()
                    default:
                        ProgressView()
                    }
                }
                .frame(width: 40, height: 40)
            }
            VStack(alignment: .leading) {
                Text(account.username)
                Text(account.xboxGamertag.isEmpty ? String(localized: "login.option.local") : account.xboxGamertag).font(Font.footnote)
            }
        }
    }
}

struct AccountView: View {
    @Binding var showModal: Bool
    @State private var showCreateLocalAccountAlert = false
    @State private var username: String = ""
    // placeholder data
    @State private var accounts = [
        Account(xboxGamertag: "", username: "test", expiresAt: 0, xuid: "none", profileId: .init(), profilePicURL: ""),
        Account(xboxGamertag: "gamertag", username: "username", expiresAt: 0, xuid: "0000000000000", profileId: .init(), profilePicURL: "https://mc-heads.net/head/9388ca89-d3ec-4ea2-938c-c21983b964e1/120")
    ]
    // var account: Account
    var body: some View {
        NavigationView {
            List {
                ForEach ($accounts, id: \.self) { $account in
                    AccountRow(account: account)
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Accounts")
            .toolbar {
                Menu("Add", systemImage: "plus") {
                    Button("Microsoft account") {}
                    Button("Local account") {
                        username = ""
                        showCreateLocalAccountAlert = true
                    }
                }
                Button(action: {showModal.toggle()}) {
                    Image(systemName: "xmark.circle.fill")
                    
                        .foregroundStyle(.gray)
                        .font(.system(.title))
                }
            }
            .alert("Sign in", isPresented: $showCreateLocalAccountAlert) {
                TextField("Username", text: $username)
                Button("OK") {
                    // conditional checks
                    accounts.insert(Account(xboxGamertag: "", username: username, expiresAt: 0, xuid: "", profileId: .init(), profilePicURL: ""), at: 0)
                    username = ""
                }
                //.disabled(username.count < 3 || username.count > 16)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Local account will not be able to download game assets.")
            }
        }
    }
    
    func delete(at offsets: IndexSet) {
        // delete the objects here
    }
}
