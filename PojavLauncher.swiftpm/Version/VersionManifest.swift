import Foundation

enum VersionType: String, Equatable, CaseIterable, Codable {
    case installed = "installed"
    case release = "release"
    case snapshot = "snapshot"
    case oldBeta = "old_beta"
    case oldAlpha = "old_alpha"
    var name: String {
        switch self {
        case .installed: return "Installed"
        case .release: return "Release"
        case .snapshot: return "Snapshot"
        case .oldBeta: return "Old Beta"
        case .oldAlpha: return "Old Alpha"
        }
    }
}

class DependentLibrary: Codable {
    
}

class FileProperties: Codable {
    var id, sha1, url: String
    var size: UInt64
}

class VersionManifest: Codable {
    class Latest: Codable {
        var release, snapshot: String
        init() {
            release = ""
            snapshot = ""
        }
    }
    
    class JavaVersionInfo: Codable {
        var component: String
        var majorVersion: Int
        var version: Int // parameter used by LabyMod 4
    }
    
    class LoggingConfig: Codable {
        class LoggingClientConfig: Codable {
            var argument: String
            // var file: FileProperties
            var type: String
        }
        var client: LoggingClientConfig
    }
    
    class Version: Codable {
        var arguments: Arguments?
        var assetIndex: AssetIndex?
        var assets: String?
        var downloads: [String : FileProperties]?
        var inheritsFrom: String?
        var javaVersion: JavaVersionInfo?
        var libraries: [DependentLibrary]?
        var logging: LoggingConfig?
        var type: VersionType
        var time, releaseTime: String
        
        // FileProperties
        var id, sha1, url: String
        var size: UInt64?
    }
    
    // 1.13+ arguments
    class Arguments: Codable {
        class ArgValue: Codable {
            var rules: [ArgRules]
            var value: String
            
            // TLauncher styled argument...
            //var values: [String]
            class ArgRules: Codable {
                class OS: Codable {
                    var name, version: String
                }
                
                var action, features: String
                var os: OS
            }
        }
        
        var game, jvm: [String]
        enum CodingKeys: String, CodingKey {
            case game, jvm
        }
        // For arguments, we need a custom decoder to filter out conditional ones
        required init(from decoder: Decoder) throws {
            game = []
            jvm = []
            let container = try decoder.container(keyedBy: CodingKeys.self)
            var gameContainer = try! container.nestedUnkeyedContainer(forKey: .game)
            var jvmContainer = try! container.nestedUnkeyedContainer(forKey: .jvm)
            while !gameContainer.isAtEnd {
                if let value = try? gameContainer.decode(String.self) {
                    game.append(value)
                } else {
                    let value = try! gameContainer.decode(ArgValue.self)
                    debugPrint("VersionManifest: skipped \(value)")
                }
            }
            while !jvmContainer.isAtEnd {
                if let value = try? jvmContainer.decode(String.self) {
                    jvm.append(value)
                } else {
                    let value = try! jvmContainer.decode(ArgValue.self)
                    debugPrint("VersionManifest: skipped \(value)")
                }
            }
        }
    }
    
    class AssetIndex: Codable {
        var totalSize: UInt64
        
        // FileProperties
        var id, sha1, url: String
        var size: UInt64
    }
    
    var latest: Latest
    var versions: [Version]
}
