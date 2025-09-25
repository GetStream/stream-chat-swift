//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// The global user push preferences and the channel push preferences for the current user.
public struct PushPreferences {
    /// The global user push preferences.
    public var userPreferences: [UserPushPreference]
    /// The push preference per channel.
    public var channelPreferences: [ChannelId: ChannelPushPreference]
}
