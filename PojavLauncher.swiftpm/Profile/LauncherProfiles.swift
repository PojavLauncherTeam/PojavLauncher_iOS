import Foundation
import SwiftUI
import UniqueID

class LauncherProfiles: Codable, ObservableObject {
    @Published var selectedProfile = "(Default)"
    @Published var profiles: [String: Profile] = [
        UUID(.timeOrdered()).uuidString: Profile()
    ]
}
