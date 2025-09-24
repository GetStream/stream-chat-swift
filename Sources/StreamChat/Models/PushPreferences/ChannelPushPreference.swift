//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// The push preference details of a channel.
public struct ChannelPushPreference {
    /// The id of the channel.
    public let channelId: ChannelId
    /// The level type of the push preference.
    public let level: PushPreferenceLevel
    /// If provided the notifications will be disabled until the set date.
    public let disabledUntil: Date?
}
