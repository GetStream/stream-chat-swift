//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CreateBlockListRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    enum CreateBlockListRequestType: String, Sendable, Codable, CaseIterable {
        case domain
        case domainAllowlist = "domain_allowlist"
        case email
        case emailAllowlist = "email_allowlist"
        case regex
        case word
        case unknown = "_unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }

    var isLeetCheckEnabled: Bool?
    var isPluralCheckEnabled: Bool?
    /// Block list name
    var name: String
    var team: String?
    /// Block list type. One of: regex, domain, domain_allowlist, email, email_allowlist, word
    var type: CreateBlockListRequestType?
    /// List of words to block
    var words: [String]

    init(isLeetCheckEnabled: Bool? = nil, isPluralCheckEnabled: Bool? = nil, name: String, team: String? = nil, words: [String]) {
        self.isLeetCheckEnabled = isLeetCheckEnabled
        self.isPluralCheckEnabled = isPluralCheckEnabled
        self.name = name
        self.team = team
        self.words = words
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case isLeetCheckEnabled = "is_leet_check_enabled"
        case isPluralCheckEnabled = "is_plural_check_enabled"
        case name
        case team
        case type
        case words
    }

    static func == (lhs: CreateBlockListRequest, rhs: CreateBlockListRequest) -> Bool {
        lhs.isLeetCheckEnabled == rhs.isLeetCheckEnabled &&
            lhs.isPluralCheckEnabled == rhs.isPluralCheckEnabled &&
            lhs.name == rhs.name &&
            lhs.team == rhs.team &&
            lhs.type == rhs.type &&
            lhs.words == rhs.words
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(isLeetCheckEnabled)
        hasher.combine(isPluralCheckEnabled)
        hasher.combine(name)
        hasher.combine(team)
        hasher.combine(type)
        hasher.combine(words)
    }
}
