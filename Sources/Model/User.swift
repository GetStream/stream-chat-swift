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

    init(id: String, name: String, avatarURL: URL?) {
        self.id = id
        self.name = name
        self.avatarURL = avatarURL
        created = Date()
        updated = Date()
        lastActiveDate = Date()
        online = false
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(id)
    }
}
