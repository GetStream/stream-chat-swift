//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct Policy: Codable, Hashable {
    public var action: Int
    public var createdAt: Date
    public var name: String
    public var owner: Bool
    public var priority: Int
    public var updatedAt: Date
    public var resources: [String]
    public var roles: [String]

    public init(action: Int, createdAt: Date, name: String, owner: Bool, priority: Int, updatedAt: Date, resources: [String], roles: [String]) {
        self.action = action
        self.createdAt = createdAt
        self.name = name
        self.owner = owner
        self.priority = priority
        self.updatedAt = updatedAt
        self.resources = resources
        self.roles = roles
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case action
        case createdAt = "created_at"
        case name
        case owner
        case priority
        case updatedAt = "updated_at"
        case resources
        case roles
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(action, forKey: .action)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(name, forKey: .name)
        try container.encode(owner, forKey: .owner)
        try container.encode(priority, forKey: .priority)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(resources, forKey: .resources)
        try container.encode(roles, forKey: .roles)
    }
}
