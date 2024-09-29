import SwiftUI

struct GameDirectory {
    static let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    static let instancesURL = documentsURL.appendingPathComponent("instances", conformingTo: .folder)

    static func createDirectory(_ name: String) {
        let directoryURL = instancesURL.appendingPathComponent(name, conformingTo: .folder)
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
    }
    
    static func removeDirectory(_ name: String) {
        let directoryURL = instancesURL.appendingPathComponent(name, conformingTo: .folder)
        try? FileManager.default.removeItem(at: directoryURL)
    }
    
    static func lpJsonPath(of name: String) -> URL {
        return instancesURL.appendingPathComponent(name + "/launcher_profiles.json", conformingTo: .fileURL)
    }
    
    static func versionsPath(of name: String) -> URL {
        return instancesURL.appendingPathComponent(name + "/versions", conformingTo: .directory)
    }
}
