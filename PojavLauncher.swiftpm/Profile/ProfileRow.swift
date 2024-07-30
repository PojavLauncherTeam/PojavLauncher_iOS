import SwiftUI

struct ProfileRow: View {
    @Binding var profile: Profile
    private var imageView: some View {
        AsyncImage(url: URL(string: profile.icon ?? "a")) { phase in
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
    var body: some View {
        NavigationLink {
            ProfileEditView(profileInput: $profile) { imageView }
        } label: {
            imageView
            VStack(alignment: .leading) {
                Text(profile.name)
                Text(profile.lastVersionId).font(Font.footnote)
            }
        }
        .listRowInsets(EdgeInsets(top: 12, leading: 15, bottom: 12, trailing: 15)) 
    }
}
