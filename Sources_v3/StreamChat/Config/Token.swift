//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type is designed to store the JWT and the user it is related to.
public struct Token: Decodable, Equatable, ExpressibleByStringLiteral {
    public let rawValue: String
    public let userId: UserId

    /// Created a new `Token` instance.
    /// - Parameter value: The JWT string value. It must be in valid format and contain `user_id` in payload.
    public init(stringLiteral value: StringLiteralType) {
        do {
            try self.init(rawValue: value)
        } catch {
            fatalError("Failed to create a `Token` instance from string literal: \(error)")
        }
    }

    /// Creates a `Token` instance from the provided `rawValue` if it's valid.
    /// - Parameter rawValue: The token string in JWT format.
    /// - Throws: `ClientError.InvalidToken` will be thrown if token string is invalid.
    public init(rawValue: String) throws {
        guard let userId = rawValue.jwtPayload?["user_id"] as? String else {
            throw ClientError.InvalidToken("Provided token does not contain `user_id`")
        }

        self.init(rawValue: rawValue, userId: userId)
    }

    init(rawValue: String, userId: UserId) {
        self.rawValue = rawValue
        self.userId = userId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        try self.init(
            rawValue: container.decode(String.self)
        )
    }
}

public extension Token {
    /// The token that can be used when user is unknown.
    ///
    /// Is used by `anonymous` token provider.
    static var anonymous: Self {
        .init(rawValue: "", userId: .anonymous)
    }

    /// The token which can be used during the development.
    ///
    /// Is used by `development(userId:)` token provider.
    static func development(userId: UserId) -> Self {
        .init(rawValue: "development", userId: userId)
    }
}

extension ClientError {
    public class InvalidToken: ClientError {}
}

private extension String {
    var jwtPayload: [String: Any]? {
        let parts = split(separator: ".")
        
        if parts.count == 3,
            let payloadData = jwtDecodeBase64(String(parts[1])),
            let json = (try? JSONSerialization.jsonObject(with: payloadData)) as? [String: Any] {
            return json
        }
        
        return nil
    }
    
    func jwtDecodeBase64(_ input: String) -> Data? {
        let removeEndingCount = input.count % 4
        let ending = removeEndingCount > 0 ? String(repeating: "=", count: 4 - removeEndingCount) : ""
        let base64 = input.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/") + ending
        
        return Data(base64Encoded: base64)
    }
}
