//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The protocol that the server uses for the events it sends over the WebSocket connection.
public struct WebSocketEventProtocol: Hashable, Sendable {
    let rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// The events include all their data.
    public static let v2 = Self(rawValue: 2)

    /// Reduces bandwidth by leaving the members out of the events of large channels.
    ///
    /// The following events of channels with more than 100 members don't include the channel members:
    /// `channel.updated`, `member.added`, `member.updated`, `member.removed`,
    /// `notification.message_new` and `notification.added_to_channel`.
    /// The members already stored locally are kept, and ``ChatChannel/memberCount`` is still updated.
    public static let v3 = Self(rawValue: 3)
}
