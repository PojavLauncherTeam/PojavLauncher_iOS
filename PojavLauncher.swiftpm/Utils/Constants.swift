import Foundation

struct Constants {
    // Note: we are not using dylib key anymore to make it align with App Store(?)
    static let renderers: KeyValuePairs = [
        "auto": "preference.title.renderer.release.auto",
        "gl4es": "preference.title.renderer.release.gl4es",
        "tinygl4angle": "preference.title.renderer.release.angle",
        "osmesa": "preference.title.renderer.release.zink"
    ]
    
    static let maxMemoryLimit = round(Double(ProcessInfo.processInfo.physicalMemory / 0x100000) * 0.85)
}
