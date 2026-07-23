//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The scope level of the push notifications.
public struct PushPreferenceLevel: RawRepresentable, Hashable, ExpressibleByStringLiteral, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: StringLiteralType) {
        rawValue = value
    }

    /// No push notifications will be delivered.
    public static let none: PushPreferenceLevel = "none"
    /// Push notifications will only be delivered for mentions.
    @available(*, deprecated, renamed: "directMentions")
    public static let mentions: PushPreferenceLevel = "mentions"
    /// Push notifications will be delivered for any kind of mention, including
    /// explicit @mentions, @channel, @here, group, and role mentions.
    public static let allMentions: PushPreferenceLevel = "all_mentions"
    /// Push notifications will only be delivered for explicit @mentions by username
    /// and thread replies.
    public static let directMentions: PushPreferenceLevel = "direct_mentions"
    /// All push notifications will be delivered.
    public static let all: PushPreferenceLevel = "all"
}

extension PushPreferenceLevel: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try? container.decode(String.self)
        self.init(rawValue: rawValue ?? Self.all.rawValue)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
