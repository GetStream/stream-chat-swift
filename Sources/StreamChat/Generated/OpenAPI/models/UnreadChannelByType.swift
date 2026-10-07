//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The unread information from channels with a specific type.
public final class UnreadChannelByType: Sendable, Decodable {
    /// The number of unread channels of this channel type.
    public let channelCount: Int
    /// The channel type.
    public let channelType: ChannelType
    /// The number of unread messages of all the channels with this type.
    public let unreadCount: Int

    init(channelCount: Int, channelType: ChannelType, unreadCount: Int) {
        self.channelCount = channelCount
        self.channelType = channelType
        self.unreadCount = unreadCount
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelCount = "channel_count"
        case channelType = "channel_type"
        case unreadCount = "unread_count"
    }
}
