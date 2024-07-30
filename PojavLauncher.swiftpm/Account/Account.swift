import Foundation

struct Account: Encodable, Hashable {
    var xboxGamertag: String = ""
    var username: String = ""
    var expiresAt: UInt64 = 0
    var xuid: String // use this for keychain lookup
    var profileId: UUID
    var profilePicURL: String = ""
}

