//
//  Member.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 18/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

public struct Member: Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case user
        case role
        case created = "created_at"
        case updated = "updated_at"
    }
    
    public let user: User
    public let created: Date
    public let updated: Date
    public let role: Role
    
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
    enum Role: String, Codable {
        case owner
    }
}
