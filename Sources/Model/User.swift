//
//  User.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

public struct User: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case avatarURL = "image"
        case online
        case created = "created_at"
        case updated = "updated_at"
        case lastActiveDate = "last_active"
    }
    
    public let id: String
    public let name: String
    public let avatarURL: URL?
    public let created: Date
    public let updated: Date
    public let lastActiveDate: Date?
    public let online: Bool
    
    public var isCurrent: Bool {
        if let user = Client.shared.user {
            return self == user
        }
        
        return false
    }
    
    public init(id: String, name: String, avatarURL: URL? = nil) {
        self.id = id
        self.name = name
        self.avatarURL = avatarURL
        created = Date()
        updated = Date()
        lastActiveDate = Date()
        online = false
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        created = try container.decode(Date.self, forKey: .created)
        updated = try container.decode(Date.self, forKey: .updated)
        lastActiveDate = try container.decodeIfPresent(Date.self, forKey: .lastActiveDate)
        online = try container.decode(Bool.self, forKey: .online)
        
        if let name = try? container.decodeIfPresent(String.self, forKey: .name) {
            self.name = name
        } else {
            name = id
        }
        
        if let avatarURL = try? container.decodeIfPresent(URL.self, forKey: .avatarURL),
           !avatarURL.absoluteString.contains("random_svg") {
            self.avatarURL = avatarURL
        } else {
            avatarURL = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(avatarURL, forKey: .avatarURL)
    }
}

extension User: Equatable, Hashable {
    
    public static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
