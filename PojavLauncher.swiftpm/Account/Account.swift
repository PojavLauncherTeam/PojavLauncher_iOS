import Foundation
import UniqueID

struct Account: Codable, Hashable {
    enum AuthType: String, Codable, Hashable {
        case msaAuthenticating
        case msaFailedAuth
        case msaDemo
        case msa
        case local
    }
    var type: AuthType = .local
    var xboxGamertag: String = ""
    var username: String = ""
    var expiresAt: UInt64 = 0
    var xuid: String = "" // use this for keychain lookup
    var profileId: UUID = UUID()
    var profilePicURL: String = ""
    var tokenData: (accessToken: String?, refreshToken: String?) {
        get {
            return getTokenData()
        }
        set {
            setTokenData(accessToken: newValue.accessToken, refreshToken: newValue.refreshToken)
        }
    }
    // uuid for PojavLauncher
    var uniqueIdentifier = UUID(.timeOrdered())
    // temporary data
    var tmpAuthcode: String?
    
    func clearTokenData() {
        SecItemDelete([
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "AccountToken",
            kSecAttrAccount: self.xuid
        ] as CFDictionary)
    }
    
    func getTokenData() -> (accessToken: String?, refreshToken: String?) {
        let dict = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "AccountToken",
            kSecAttrAccount: self.xuid,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnData: kCFBooleanTrue as Any
        ] as CFDictionary
        var dataObject: AnyObject?
        let status = SecItemCopyMatching(dict, &dataObject)
        if status == errSecSuccess,
           let data = dataObject as? Data,
           let result = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSDictionary.self, from: data) as? [String : String] {
            return (result["accessToken"], result["refreshToken"])
        } else {
            return (nil, nil)
        }
    }
    
    func setTokenData(accessToken: String?, refreshToken: String?) {
        let data = try! NSKeyedArchiver.archivedData(withRootObject: [
            "accessToken": accessToken,
            "refreshToken": refreshToken
        ], requiringSecureCoding: true)
        let dict = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "AccountToken",
            kSecAttrAccount: self.xuid,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData: data
        ] as CFDictionary
        SecItemDelete(dict)
        let status = SecItemAdd(dict, nil)
        if status != errSecSuccess {
            print("Account: failed to set token data")
        }
        //return status == errSecSuccess
    }
}

