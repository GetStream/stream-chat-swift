//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object describing a role JSON payload.
struct RolePayload: Decodable, Sendable {
    let name: String
    let custom: Bool
    let scopes: [String]
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case name
        case custom
        case scopes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        custom = try container.decodeIfPresent(Bool.self, forKey: .custom) ?? false
        scopes = try container.decodeIfPresent([String].self, forKey: .scopes) ?? []
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }

    init(
        name: String,
        custom: Bool = false,
        scopes: [String] = [],
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.name = name
        self.custom = custom
        self.scopes = scopes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func asModel() -> Role {
        Role(
            name: name,
            isCustom: custom,
            scopes: scopes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

/// A response containing a list of roles.
struct RoleListPayload: Decodable, Sendable {
    let roles: [RolePayload]

    enum CodingKeys: String, CodingKey {
        case roles
    }
}
