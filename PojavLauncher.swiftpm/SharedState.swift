import SwiftUI

class SharedState: ObservableObject {
    @Published var currentAuthStep = ""
    @Published var isMSALoggingIn = false
}
