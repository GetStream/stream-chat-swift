//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class Role: Sendable, Codable, JSONEncodable {
    /// Date/time of creation
    public let createdAt: Date?
    /// Whether this is a custom role or built-in
    public let custom: Bool
    /// Unique role name
    public let name: String
    /// List of scopes where this role is currently present. `.app` means that role is present in app-level grants
    public let scopes: [String]
    /// Date/time of the last update
    public let updatedAt: Date?

    init(
        createdAt: Date? = nil,
        custom: Bool,
        name: String,
        scopes: [String],
        updatedAt: Date? = nil
    ) {
        self.createdAt = createdAt
        self.custom = custom
        self.name = name
        self.scopes = scopes
        self.updatedAt = updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.custom = try container.decode(Bool.self, forKey: .custom)
        self.name = try container.decode(String.self, forKey: .name)
        self.scopes = try container.decode([String].self, forKey: .scopes)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encode(custom, forKey: .custom)
        try container.encode(name, forKey: .name)
        try container.encode(scopes, forKey: .scopes)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
}

extension Role: Hashable {
    public static func == (lhs: Role, rhs: Role) -> Bool {
        lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.name == rhs.name &&
            lhs.scopes == rhs.scopes &&
            lhs.updatedAt == rhs.updatedAt
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(name)
        hasher.combine(scopes)
        hasher.combine(updatedAt)
    }
}
