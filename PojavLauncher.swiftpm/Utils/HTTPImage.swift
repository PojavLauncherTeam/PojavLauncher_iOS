import SwiftUI

struct HTTPImage: View {
    var url: String?
    var defaultImageName: String
    var body: some View {
        let urlEmpty = url?.isEmpty ?? true
        AsyncImage(url: URL(string: urlEmpty ? "a" : url!)) { phase in
            switch phase {
            case .failure:
                Image(defaultImageName)
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
