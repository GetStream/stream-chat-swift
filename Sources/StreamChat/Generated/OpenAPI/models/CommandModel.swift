//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CommandModel: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Arguments help text, shown in commands auto-completion
    var args: String
    /// Date/time of creation
    var createdAt: Date?
    /// Description, shown in commands auto-completion
    var description: String
    /// Unique command name
    var name: String
    /// Set name used for grouping commands
    var set: String
    /// Date/time of the last update
    var updatedAt: Date?

    init(args: String, createdAt: Date? = nil, description: String, name: String, set: String, updatedAt: Date? = nil) {
        self.args = args
        self.createdAt = createdAt
        self.description = description
        self.name = name
        self.set = set
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case args
        case createdAt = "created_at"
        case description
        case name
        case set
        case updatedAt = "updated_at"
    }

    static func == (lhs: CommandModel, rhs: CommandModel) -> Bool {
        lhs.args == rhs.args &&
            lhs.createdAt == rhs.createdAt &&
            lhs.description == rhs.description &&
            lhs.name == rhs.name &&
            lhs.set == rhs.set &&
            lhs.updatedAt == rhs.updatedAt
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(args)
        hasher.combine(createdAt)
        hasher.combine(description)
        hasher.combine(name)
        hasher.combine(set)
        hasher.combine(updatedAt)
    }
}
