//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The push preference details.
public final class PushPreference: Sendable, Decodable {
    /// The scope level of the push notifications.
    private let _level: PushPreferenceLevel?
    public var level: PushPreferenceLevel { _level ?? .all }
    /// If provided the notifications will be disabled until the set date.
    public let disabledUntil: Date?

    init(level: PushPreferenceLevel? = nil, disabledUntil: Date? = nil) {
        self._level = level
        self.disabledUntil = disabledUntil
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case _level = "chat_level"
        case disabledUntil = "disabled_until"
    }
}

extension PushPreference: Hashable {
    public static func == (lhs: PushPreference, rhs: PushPreference) -> Bool {
        lhs.level == rhs.level &&
            lhs.disabledUntil == rhs.disabledUntil
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(level)
        hasher.combine(disabledUntil)
    }
}
