//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class PushPreferenceLevel: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Behaves as all.
    public static let `default` = PushPreferenceLevel(rawValue: "default")
    /// All push notifications will be delivered.
    public static let all = PushPreferenceLevel(rawValue: "all")
    /// Push notifications will only be delivered when the user is mentioned directly or via @channel, @here, a role or a user group.
    public static let allMentions = PushPreferenceLevel(rawValue: "all_mentions")
    /// Push notifications will only be delivered when the user is directly @mentioned by username.
    public static let directMentions = PushPreferenceLevel(rawValue: "direct_mentions")
    /// Deprecated: behaves as direct_mentions.
    @available(*, deprecated, renamed: "directMentions")
    public static let mentions = PushPreferenceLevel(rawValue: "mentions")
    /// No push notifications will be delivered.
    public static let none = PushPreferenceLevel(rawValue: "none")
}

final class PushPreferenceInput: Sendable, Encodable, JSONEncodable {
    /// Set the push preferences for a specific channel. If empty it sets the default for the user
    let channelCid: String?
    /// Set the level of chat push notifications for the user. Note: "mentions" is deprecated in favor of "direct_mentions". One of: all, mentions, direct_mentions, all_mentions, none, default
    let chatLevel: PushPreferenceLevel?
    /// Disable push notifications till a certain time
    let disabledUntil: Date?
    /// Remove the disabled until time. (IE stop snoozing notifications)
    let removeDisable: Bool?
    /// Remove the user's quiet-hours schedule, the counterpart of remove_disable. It is applied before schedule, so sending both in one item replaces the stored schedule instead of merging into it. Cannot be combined with channel_cid. To switch from a schedule to a snooze, send remove_schedule together with disabled_until.
    let removeSchedule: Bool?
    /// A recurring quiet-hours schedule: while any quiet window is active, push notifications for the user are suppressed. Suppressed notifications are dropped, not delayed.
    let schedule: PushScheduleInput?

    init(
        channelCid: String? = nil,
        chatLevel: PushPreferenceLevel? = nil,
        disabledUntil: Date? = nil,
        removeDisable: Bool? = nil,
        removeSchedule: Bool? = nil,
        schedule: PushScheduleInput? = nil
    ) {
        self.channelCid = channelCid
        self.chatLevel = chatLevel
        self.disabledUntil = disabledUntil
        self.removeDisable = removeDisable
        self.removeSchedule = removeSchedule
        self.schedule = schedule
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(channelCid, forKey: .channelCid)
        try container.encodeIfPresent(chatLevel, forKey: .chatLevel)
        try container.encodeIfPresent(disabledUntil, forKey: .disabledUntil)
        try container.encodeIfPresent(removeDisable, forKey: .removeDisable)
        try container.encodeIfPresent(removeSchedule, forKey: .removeSchedule)
        try container.encodeIfPresent(schedule, forKey: .schedule)
    }
}

extension PushPreferenceInput: Hashable {
    static func == (lhs: PushPreferenceInput, rhs: PushPreferenceInput) -> Bool {
        lhs.channelCid == rhs.channelCid &&
            lhs.chatLevel == rhs.chatLevel &&
            lhs.disabledUntil == rhs.disabledUntil &&
            lhs.removeDisable == rhs.removeDisable &&
            lhs.removeSchedule == rhs.removeSchedule &&
            lhs.schedule == rhs.schedule
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channelCid)
        hasher.combine(chatLevel)
        hasher.combine(disabledUntil)
        hasher.combine(removeDisable)
        hasher.combine(removeSchedule)
        hasher.combine(schedule)
    }
}
