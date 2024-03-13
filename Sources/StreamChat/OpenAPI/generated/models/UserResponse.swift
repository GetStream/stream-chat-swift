//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UserResponse: Codable, Hashable {
    public var banned: Bool
    public var createdAt: Date
    public var id: String
    public var language: String
    public var online: Bool
    public var updatedAt: Date
    public var deletedAt: Date? = nil
    public var image: String? = nil
    public var name: String? = nil
    public var custom: [String: RawJSON]? = nil

    public init(banned: Bool, createdAt: Date, id: String, language: String, online: Bool, updatedAt: Date, deletedAt: Date? = nil, image: String? = nil, name: String? = nil, custom: [String: RawJSON]? = nil) {
        self.banned = banned
        self.createdAt = createdAt
        self.id = id
        self.language = language
        self.online = online
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.image = image
        self.name = name
        self.custom = custom
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case banned
        case createdAt = "created_at"
        case id
        case language
        case online
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case image
        case name
        case custom
    }
}
