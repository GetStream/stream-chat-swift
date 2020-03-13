//
//  Token.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 09/07/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A token.
public typealias Token = String

/// A token provider is a function in which you send a request to your own backend to get a Stream Chat API token.
/// Then you send it to the client to complete the setup with a callback function from the token provider.
public typealias TokenProvider = (@escaping (Token) -> Void) -> Void

extension Token {
    /// A development token.
    public static let development: Token = "development"
    
    /// Checks if the token is valid.
    public func isValidToken(userId: String = User.current.id) -> Bool {
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

// MARK: - Token response

struct TokenResponse: Decodable {
    private enum CodingKeys: String, CodingKey {
        case user
        case token = "access_token"
    }
    
    let user: User
    let token: Token
}
