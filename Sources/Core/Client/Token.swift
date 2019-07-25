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
    /// A guest token.
    public static let guest: Token = "guest"
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
