import Foundation

struct Constants {
    static let msaAuthURL = URL(string: "https://login.live.com/oauth20_authorize.srf?client_id=00000000402b5328&response_type=code&scope=service%3A%3Auser.auth.xboxlive.com%3A%3AMBI_SSL&redirect_url=https%3A%2F%2Flogin.live.com%2Foauth20_desktop.srf")!
    static let msaAuthCallbackURLScheme = "ms-xal-00000000402b5328"
    
    // Note: we are not using dylib key anymore to make it align with App Store(?)
    static let renderers: KeyValuePairs = [
        "auto": "preference.title.renderer.release.auto",
        "gl4es": "preference.title.renderer.release.gl4es",
        "tinygl4angle": "preference.title.renderer.release.angle",
        "osmesa": "preference.title.renderer.release.zink"
    ]
    
    static let maxMemoryLimit = round(Double(ProcessInfo.processInfo.physicalMemory / 0x100000) * 0.85)
    static let zeroUUIDString = "00000000-0000-0000-0000-000000000000"
}
