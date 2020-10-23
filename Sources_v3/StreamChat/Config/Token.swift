//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A token is used to authenticate a user.
public typealias Token = String

/// A token provider is a function in which you send a request to your own backend to get a Stream Chat API token.
///
/// Set your custom `TokenProvider` in `ChatClientConfig` when creating a `ChatClient` instance. `ChatClient` will use it whenever
/// it needs to get a new token for the given user.
///
public typealias TokenProvider = (_ apiKey: APIKey, _ userId: UserId, _ completion: @escaping (Token?) -> Void) -> Void

extension Token {
    /// A token which can be used during development.
    public static let development: Token = "development"
    
    /// Locally checks if the provided token is valid for the given user id.
    ///
    /// A token is a string in the JSON Web Token format and one of the parameters it contains is the id of the given user. This
    /// makes it possible to locally check if the token is valid for the given user.
    ///
    /// - Warning: The fact that the token is valid for the given user doesn't mean it can't be rejected by the servers. This is
    /// a required but not sufficient condition.
    ///
    public func isValid(for userId: UserId) -> Bool {
        if self == .development {
            return true
        }
        
        return !userId.isEmpty && (payload?["user_id"] as? String) == userId
    }
    
    var payload: [String: Any]? {
        let parts = split(separator: ".")
        
        if parts.count == 3,
            let payloadData = jwtDecodeBase64(String(parts[1])),
            let json = (try? JSONSerialization.jsonObject(with: payloadData)) as? [String: Any] {
            return json
        }
        
        return nil
    }
    
    private func jwtDecodeBase64(_ input: String) -> Data? {
        let removeEndingCount = input.count % 4
        let ending = removeEndingCount > 0 ? String(repeating: "=", count: 4 - removeEndingCount) : ""
        let base64 = input.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/") + ending
        
        return Data(base64Encoded: base64)
    }
}
