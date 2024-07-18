//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CryptoKit
import Foundation
import StreamChat

extension StreamChatWrapper {
    func refreshingTokenProvider(
        initialToken: Token,
        refreshDetails: DemoAppConfig.TokenRefreshDetails
    ) -> TokenProvider {
        { completion in
            // Simulate API call delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let generatedToken: Token? = _generateUserToken(
                    secret: refreshDetails.appSecret,
                    userID: initialToken.userId,
                    expirationDate: Date().addingTimeInterval(refreshDetails.duration)
                )

                if generatedToken == nil {
                    log.error("Demo App Token Refreshing: Unable to generate token. Using initialToken instead.")
                }

                let numberOfSuccessfulRefreshes = refreshDetails.numberOfSuccessfulRefreshesBeforeFailing
                let shouldNotFail = numberOfSuccessfulRefreshes == 0
                if shouldNotFail || self.numberOfRefreshTokens >= numberOfSuccessfulRefreshes {
                    print("Demo App Token Refreshing: New token generated successfully.")
                    let newToken = generatedToken ?? initialToken
                    completion(.success(newToken))
                } else {
                    print("Demo App Token Refreshing: Token refresh failed.")
                    completion(.failure(ClientError("Token Refresh Failed")))
                }
                self.numberOfRefreshTokens += 1
            }
        }
    }
}

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
