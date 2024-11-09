import SwiftUI

struct ProfileRow: View {
    @ObservedObject var profile: Profile
    @Binding var selection: String?
    var tag: String
    var body: some View {
        NavigationLink(tag: tag, selection: $selection) {
            ProfileEditView(profile: profile)
        } label: {
            HTTPImage(url: profile.icon, defaultImageName: "DefaultProfile")
            VStack(alignment: .leading) {
                Text(profile.name)
                Text(profile.lastVersionId).font(Font.footnote)
            }
        }
        .listRowInsets(EdgeInsets(top: 12, leading: 15, bottom: 12, trailing: 15)) 
    }
}
