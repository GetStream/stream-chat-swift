//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BlockListResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Date/time of creation
    var createdAt: Date?
    var id: String?
    var isLeetCheckEnabled: Bool
    var isPluralCheckEnabled: Bool
    /// Block list name
    var name: String
    var team: String?
    /// Block list type. One of: regex, domain, domain_allowlist, email, email_allowlist, word
    var type: String
    /// Date/time of the last update
    var updatedAt: Date?
    /// List of words to block
    var words: [String]

    init(createdAt: Date? = nil, id: String? = nil, isLeetCheckEnabled: Bool, isPluralCheckEnabled: Bool, name: String, team: String? = nil, type: String, updatedAt: Date? = nil, words: [String]) {
        self.createdAt = createdAt
        self.id = id
        self.isLeetCheckEnabled = isLeetCheckEnabled
        self.isPluralCheckEnabled = isPluralCheckEnabled
        self.name = name
        self.team = team
        self.type = type
        self.updatedAt = updatedAt
        self.words = words
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case id
        case isLeetCheckEnabled = "is_leet_check_enabled"
        case isPluralCheckEnabled = "is_plural_check_enabled"
        case name
        case team
        case type
        case updatedAt = "updated_at"
        case words
    }

    static func == (lhs: BlockListResponse, rhs: BlockListResponse) -> Bool {
        lhs.createdAt == rhs.createdAt &&
            lhs.id == rhs.id &&
            lhs.isLeetCheckEnabled == rhs.isLeetCheckEnabled &&
            lhs.isPluralCheckEnabled == rhs.isPluralCheckEnabled &&
            lhs.name == rhs.name &&
            lhs.team == rhs.team &&
            lhs.type == rhs.type &&
            lhs.updatedAt == rhs.updatedAt &&
            lhs.words == rhs.words
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(id)
        hasher.combine(isLeetCheckEnabled)
        hasher.combine(isPluralCheckEnabled)
        hasher.combine(name)
        hasher.combine(team)
        hasher.combine(type)
        hasher.combine(updatedAt)
        hasher.combine(words)
    }
}
