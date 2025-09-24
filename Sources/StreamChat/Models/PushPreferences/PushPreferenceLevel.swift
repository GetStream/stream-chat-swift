//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// The scope level of the push notifications.
public struct PushPreferenceLevel: RawRepresentable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: StringLiteralType) {
        rawValue = value
    }

    /// No push notifications will be delivered.
    public static var none: PushPreferenceLevel = "none"
    /// Push notifications will only be delivered for mentions.
    public static var mentions: PushPreferenceLevel = "mentions"
    /// All push notifications will be delivered.
    public static var all: PushPreferenceLevel = "all"
}
