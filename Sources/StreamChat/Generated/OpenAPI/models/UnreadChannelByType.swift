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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channelCount = try container.decode(Int.self, forKey: .channelCount)
        self.channelType = try container.decode(ChannelType.self, forKey: .channelType)
        self.unreadCount = try container.decode(Int.self, forKey: .unreadCount)
    }
}
