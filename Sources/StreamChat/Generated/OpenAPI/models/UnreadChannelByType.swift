//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class UnreadChannelByType: Sendable, Decodable {
    public let channelCount: Int
    public let channelType: ChannelType
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
