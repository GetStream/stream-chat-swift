//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// How many scheduled messages the current user has, next to the limits of the app.
///
/// The counts come from the scheduled messages saved locally, so they can lag behind the server.
/// Failed scheduled messages don't count, except ones whose edit failed, because the server still has them.
public struct ScheduledMessagesUsage: Equatable, Sendable {
    /// The number of scheduled messages in the channel.
    public let channelCount: Int

    /// How many scheduled messages the current user can have in the channel. `nil` when the channel isn't stored
    /// locally, or scheduled messages aren't enabled for the app.
    public let channelLimit: Int?

    /// The number of scheduled messages in all channels.
    public let userCount: Int

    /// How many scheduled messages the current user can have in all channels. `nil` when the channel isn't stored
    /// locally, or scheduled messages aren't enabled for the app.
    public let userLimit: Int?
}
