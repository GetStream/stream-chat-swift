//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UnreadCountsChannelType: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var channelCount: Int
    var channelType: String
    var unreadCount: Int

    init(channelCount: Int, channelType: String, unreadCount: Int) {
        self.channelCount = channelCount
        self.channelType = channelType
        self.unreadCount = unreadCount
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelCount = "channel_count"
        case channelType = "channel_type"
        case unreadCount = "unread_count"
    }

    static func == (lhs: UnreadCountsChannelType, rhs: UnreadCountsChannelType) -> Bool {
        lhs.channelCount == rhs.channelCount &&
            lhs.channelType == rhs.channelType &&
            lhs.unreadCount == rhs.unreadCount
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channelCount)
        hasher.combine(channelType)
        hasher.combine(unreadCount)
    }
}
