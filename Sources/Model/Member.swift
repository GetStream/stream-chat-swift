//
//  Member.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 18/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A member.
public struct Member: Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case user
        case role
        case created = "created_at"
        case updated = "updated_at"
    }
    
    /// A user.
    public let user: User
    /// A role of the user.
    public let role: Role
    /// A created date.
    public let created: Date
    /// A updated date.
    public let updated: Date
    
    init(user: User, role: Role = .owner) {
        self.user = user
        self.role = role
        created = Date()
        updated = Date()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(user.id, forKey: .user)
        try container.encode(role, forKey: .role)
    }
}

public extension Member {
    /// A role.
    enum Role: String, Codable {
        case owner
        case member
        case user
    }
}
