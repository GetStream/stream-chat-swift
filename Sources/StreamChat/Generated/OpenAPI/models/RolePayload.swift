//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class RolePayload: Sendable, Codable, JSONEncodable {
    /// Date/time of creation
    let createdAt: Date
    /// Whether this is a custom role or built-in
    let custom: Bool
    /// Unique role name
    let name: String
    /// List of scopes where this role is currently present. `.app` means that role is present in app-level grants
    let scopes: [String]
    /// Date/time of the last update
    let updatedAt: Date

    init(createdAt: Date, custom: Bool, name: String, scopes: [String], updatedAt: Date) {
        self.createdAt = createdAt
        self.custom = custom
        self.name = name
        self.scopes = scopes
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case custom
        case name
        case scopes
        case updatedAt = "updated_at"
    }
}
