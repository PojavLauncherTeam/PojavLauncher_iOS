import Alamofire
import Foundation

struct MicrosoftAuth {
    struct TokenRequest: Codable {
        struct Properties: Codable {
            var AuthMethod, SiteName, RpsTicket, SandboxId: String?
            var UserTokens: [String]?
        }
        var Properties: Properties
        var RelyingParty, TokenType: String
    }
    
    class MSTokenResponse: Codable {
        var access_token, refresh_token: String
        var expires_in: Int
    }
    
    class MCTokenResponse: Codable {
        var access_token: String
    }
    
    class XSTSResponse: Codable {
        class DisplayClaims: Codable {
            class XUI: Codable {
                var uhs: String
            }
            var xui: [XUI]
        }
        var DisplayClaims: DisplayClaims
        var Token: String
    }
    
    class XboxProfileResponse: Codable {
        class ProfileUser: Codable {
            class KeyValuePair: Codable {
                var id, value: String
            }
            var settings: [KeyValuePair]
        }
        var profileUsers: [ProfileUser]
    }
    
    class MCProfileResponse: Codable {
        // For paid accounts
        var id: String?
        var name: String?
        // For demo accounts, error must be NOT_FOUND
        var error: String?
        var errorMessage: String?
    }
    
    static func acquireAccessToken(authcode: String, refresh: Bool) async throws -> (refreshToken: String, accessToken: String) {
        print("MSA: acquireAccessToken with refresh: \(refresh)")
        let tokenType = refresh ? "refresh_token" : "code"
        let data = [
            "client_id": "00000000402b5328",
            tokenType: authcode,
            "grant_type": refresh ? "refresh_token" : "authorization_code",
            "redirect_url": "https://login.live.com/oauth20_desktop.srf",
            "scope": "service::user.auth.xboxlive.com::MBI_SSL"
        ]
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(
                "https://login.live.com/oauth20_token.srf",
                parameters: data
            )
            .responseDecodable(of: MSTokenResponse.self) { response in
                switch response.result {
                case let .success(result):
                    continuation.resume(returning: (refreshToken: result.refresh_token, accessToken: result.access_token))
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    static func acquireXBLToken(accessToken: String) async throws -> String {
        print("MSA: acquireXBLToken")
        let data = TokenRequest(
            Properties: TokenRequest.Properties(
                AuthMethod: "RPS",
                SiteName: "user.auth.xboxlive.com",
                RpsTicket: accessToken
            ),
            RelyingParty: "http://auth.xboxlive.com",
            TokenType: "JWT"
        )
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(
                "https://user.auth.xboxlive.com/user/authenticate",
                method: .post, parameters: data,
                encoder: JSONParameterEncoder.default
            )
            .responseDecodable(of:  XSTSResponse.self) { response in
                switch response.result {
                case let .success(result):
                    continuation.resume(returning: result.Token)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    static func acquireXSTS(for relyingParty: String, xblToken: String) async throws -> (xsts: String, uhs: String) {
        print("MSA: acquireXSTS party: \(relyingParty)")
        let data = TokenRequest(
            Properties: TokenRequest.Properties(
                SandboxId: "RETAIL",
                UserTokens: [xblToken]
            ),
            RelyingParty: relyingParty,
            TokenType: "JWT"
        )
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(
                "https://xsts.auth.xboxlive.com/xsts/authorize",
                method: .post, parameters: data,
                encoder: JSONParameterEncoder.default
            )
            .responseDecodable(of: XSTSResponse.self) { response in
                switch response.result {
                case let .success(result):
                    continuation.resume(returning: (xsts: result.Token, uhs: result.DisplayClaims.xui.first!.uhs))
                case let .failure(error):
                    // TODO: handle XErr
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    static func acquireXboxProfile(xblUhs: String, xblXsts: String) async throws -> (profilePicURL: String, xboxGamertag: String) {
        print("MSA: acquireXboxProfile")
        let headers: HTTPHeaders = [
            "x-xbl-contract-version": "2",
            "Authorization": "XBL3.0 x=\(xblUhs);\(xblXsts)"
        ]
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(
                "https://profile.xboxlive.com/users/me/profile/settings?settings=PublicGamerpic,Gamertag",
                headers: headers
            )
            .responseDecodable(of: XboxProfileResponse.self) { response in
                switch response.result {
                case let .success(result):
                    let settings = result.profileUsers.first!.settings
                    continuation.resume(returning: (profilePicURL: settings[0].value, xboxGamertag: settings[1].value))
                case let .failure(error):
                    // TODO: handle XErr
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    static func acquireMinecraftToken(xblUhs: String, xblXsts: String) async throws -> String {
        print("MSA: acquireMinecraftToken")
        let data = [
            "identityToken": "XBL3.0 x=\(xblUhs);\(xblXsts)"
        ]
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(
                "https://api.minecraftservices.com/authentication/login_with_xbox",
                method: .post, parameters: data,
                encoder: JSONParameterEncoder.default
            )
            .responseDecodable(of: MCTokenResponse.self) { response in
                switch response.result {
                case let .success(result):
                    continuation.resume(returning: result.access_token)
                case let .failure(error):
                    // TODO: handle XErr
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    static func checkMinecraftProfile(accessToken: String) async throws -> MCProfileResponse {
        print("MSA: checkMinecraftProfile")
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)"
        ]
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(
                "https://api.minecraftservices.com/minecraft/profile",
                headers: headers
            )
            .responseDecodable(of: MCProfileResponse.self) { response in
                switch response.result {
                case let .success(result):
                    if result.id == nil {
                        result.id = Constants.zeroUUIDString
                    } else {
                        result.id = "\(result.id![0..<8])-\(result.id![8..<12])-\(result.id![12..<16])-\(result.id![16..<20])-\(result.id![20..<32])"
                    }
                    continuation.resume(returning: result)
                case let .failure(error):
                    // TODO: handle XErr
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
