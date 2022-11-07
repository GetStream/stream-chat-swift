//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

extension StreamChatWrapper {
    func refreshingTokenProvider(initialToken: Token, tokenDurationInMinutes: Double) -> TokenProvider {
        { completion in
            // Simulate API call delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let token: Token
                #if GENERATE_JWT
                let timeInterval = TimeInterval(tokenDurationInMinutes * 60)
                let generatedToken = _generateUserToken(
                    secret: appSecret,
                    userID: initialToken.userId,
                    expirationDate: Date().addingTimeInterval(timeInterval)
                )
                if generatedToken == nil {
                    log.warning("Unable to generate token. Falling back to initialToken")
                }
                token = generatedToken ?? initialToken
                #else
                token = initialToken
                #endif
                completion(.success(token))
            }
        }
    }
}

#if GENERATE_JWT

import CryptoKit
import Foundation
import StreamChat

let appSecret = ""

extension Data {
    func urlSafeBase64EncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

struct Header: Encodable {
    let alg = "HS256"
    let typ = "JWT"
}

struct JWTPayload: Encodable {
    let user_id: String
    let exp: Int
}

// DO NOT USE THIS FOR REAL APPS! This function is only here to make it easier to
// have expired token renewal while using the standalone demo application
func _generateUserToken(secret: String, userID: String, expirationDate: Date) -> Token? {
    guard !secret.isEmpty else { return nil }
    let privateKey = SymmetricKey(data: secret.data(using: .utf8)!)

    guard let headerJSONData = try? JSONEncoder().encode(Header()) else { return nil }
    let headerBase64String = headerJSONData.urlSafeBase64EncodedString()

    let expiration = Int(expirationDate.timeIntervalSince1970)
    guard let payloadJSONData = try? JSONEncoder().encode(JWTPayload(user_id: userID, exp: expiration)) else { return nil }
    let payloadBase64String = payloadJSONData.urlSafeBase64EncodedString()

    let toSign = (headerBase64String + "." + payloadBase64String).data(using: .utf8)!
    let signature = HMAC<SHA256>.authenticationCode(for: toSign, using: privateKey)
    let signatureBase64String = Data(signature).urlSafeBase64EncodedString()

    let token = [headerBase64String, payloadBase64String, signatureBase64String].joined(separator: ".")
    return try? Token(rawValue: token)
}

#endif
