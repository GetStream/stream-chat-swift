//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The push preference details.
public struct PushPreference: Equatable, Sendable {
    /// The scope level of the push notifications.
    public let level: PushPreferenceLevel
    /// If provided the notifications will be disabled until the set date.
    public let disabledUntil: Date?
    /// The chat push notification preferences per mention type.
    public let chatPreferences: ChatPreferences?

    init(level: PushPreferenceLevel, disabledUntil: Date?, chatPreferences: ChatPreferences? = nil) {
        self.level = level
        self.disabledUntil = disabledUntil
        self.chatPreferences = chatPreferences
    }
}

extension PushPreferencesResponse {
    func asModel() -> PushPreference {
        .init(
            level: PushPreferenceLevel(rawValue: chatLevel ?? PushPreferenceLevel.all.rawValue),
            disabledUntil: disabledUntil,
            chatPreferences: chatPreferences
        )
    }
}
