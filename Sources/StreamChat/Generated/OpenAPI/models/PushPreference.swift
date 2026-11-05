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
    /// A recurring quiet-hours schedule: while any quiet window is active, push notifications for the user are suppressed. Suppressed notifications are dropped, not delayed.
    public let schedule: PushSchedule?

    init(
        level: PushPreferenceLevel? = nil,
        disabledUntil: Date? = nil,
        schedule: PushSchedule? = nil
    ) {
        self._level = level
        self.disabledUntil = disabledUntil
        self.schedule = schedule
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self._level = try container.decodeIfPresent(PushPreferenceLevel.self, forKey: .chatLevel)
        self.disabledUntil = try container.decodeIfPresent(Date.self, forKey: .disabledUntil)
        self.schedule = try container.decodeIfPresent(PushSchedule.self, forKey: .schedule)
    }
}

extension PushPreference: Hashable {
    public static func == (lhs: PushPreference, rhs: PushPreference) -> Bool {
        lhs.level == rhs.level &&
            lhs.disabledUntil == rhs.disabledUntil &&
            lhs.schedule == rhs.schedule
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(level)
        hasher.combine(disabledUntil)
        hasher.combine(schedule)
    }
}
