//
//  MutedUser.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 20/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A muted user.
public struct MutedUser: Decodable {
    private enum CodingKeys: String, CodingKey {
        case user = "target"
        case created = "created_at"
        case updated = "updated_at"
    }
    
    /// A muted user.
    public let user: User
    /// A created date.
    public let created: Date
    /// A updated date.
    public let updated: Date
    
    /// Create a muted user for a database.
    /// - Parameters:
    ///   - user: a user.
    ///   - created: a created date.
    ///   - updated: an updated date.
    public init(user: User, created: Date, updated: Date) {
        self.user = user
        self.created = created
        self.updated = updated
    }
}

/// A muted users response.
public struct MutedUsersResponse: Decodable {
    private enum CodingKeys: String, CodingKey {
        case mutedUser = "mute"
        case currentUser = "own_user"
    }
    
    /// A muted user.
    public let mutedUser: MutedUser
    /// The current user.
    public let currentUser: User
}
