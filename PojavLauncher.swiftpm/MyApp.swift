import SwiftUI

@main
struct MyApp: App {
    init() {
        GameDirectory.createDirectory("default")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
