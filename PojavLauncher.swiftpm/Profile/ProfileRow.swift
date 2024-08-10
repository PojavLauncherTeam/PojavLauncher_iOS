import SwiftUI

struct ProfileImage: View {
    var url: String?
    var body: some View {
        AsyncImage(url: URL(string: url ?? "a")) { phase in
            switch phase {
            case .failure:
                Image("DefaultProfile")
                    .resizable()
            case .success(let image):
                image
                    .resizable()
            default:
                ProgressView()
            }
        }
        .frame(width: 40, height: 40)
        .listRowInsets(EdgeInsets())
    }
}

struct ProfileRow: View {
    @ObservedObject var profile: Profile
    var body: some View {
        NavigationLink {
            ProfileEditView(profile: profile)
        } label: {
            ProfileImage(url: profile.icon)
            VStack(alignment: .leading) {
                Text(profile.name)
                Text(profile.lastVersionId).font(Font.footnote)
            }
        }
        .listRowInsets(EdgeInsets(top: 12, leading: 15, bottom: 12, trailing: 15)) 
    }
}
