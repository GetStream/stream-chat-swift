//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct QueryUserResult: Codable, Hashable {
    public var banned: Bool
    public var createdAt: Date
    public var id: String
    public var language: String
    public var online: Bool
    public var role: String
    public var shadowBanned: Bool
    public var updatedAt: Date
    public var teams: [String]
    public var custom: [String: RawJSON]
    public var deletedAt: Date? = nil
    public var image: String? = nil
    public var name: String? = nil
    public var revokeTokensIssuedBefore: Date? = nil

    public init(banned: Bool, createdAt: Date, id: String, language: String, online: Bool, role: String, shadowBanned: Bool, updatedAt: Date, teams: [String], custom: [String: RawJSON], deletedAt: Date? = nil, image: String? = nil, name: String? = nil, revokeTokensIssuedBefore: Date? = nil) {
        self.banned = banned
        self.createdAt = createdAt
        self.id = id
        self.language = language
        self.online = online
        self.role = role
        self.shadowBanned = shadowBanned
        self.updatedAt = updatedAt
        self.teams = teams
        self.custom = custom
        self.deletedAt = deletedAt
        self.image = image
        self.name = name
        self.revokeTokensIssuedBefore = revokeTokensIssuedBefore
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case banned
        case createdAt = "created_at"
        case id
        case language
        case online
        case role
        case shadowBanned = "shadow_banned"
        case updatedAt = "updated_at"
        case teams
        case custom
        case deletedAt = "deleted_at"
        case image
        case name
        case revokeTokensIssuedBefore = "revoke_tokens_issued_before"
    }
}
