//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// The scope level of the push notifications.
public struct PushPreferenceLevel: RawRepresentable, Equatable, ExpressibleByStringLiteral, Sendable {
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
    public static let mentions: PushPreferenceLevel = "mentions"
    /// All push notifications will be delivered.
    public static let all: PushPreferenceLevel = "all"
}
