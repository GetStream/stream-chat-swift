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
}

extension PushPreferencesResponse {
    func asModel() -> PushPreference {
        .init(
            level: PushPreferenceLevel(rawValue: chatLevel ?? PushPreferenceLevel.all.rawValue),
            disabledUntil: disabledUntil
        )
    }
}

extension ChannelPushPreferencesResponse {
    func asModel() -> PushPreference {
        .init(
            level: PushPreferenceLevel(rawValue: chatLevel ?? PushPreferenceLevel.all.rawValue),
            disabledUntil: disabledUntil
        )
    }
}
