//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

// TODO: v5: Because we mix the UnreadCount Domain model with Payload we have to set `threads` optional.
// The reason is because when mapping the unread count from `CurrentUserDTO` we know `threads` can't be null, and will be at least be 0.
// But since this structure is used to parse unread count from WSEvents, in those events `threads` can be null sometimes, so we have to set it null here.

/// A struct containing information about unread counts of channels and messages.
public struct UnreadCount: Decodable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case currentUserUnreadCount = "me"
        case userUnreadCount = "user"
        case channels = "unread_channels"
        case messages = "total_unread_count"
        case threads = "unread_threads"
    }

    /// The default value representing no unread channels, messages and threads.
    public static let noUnread = UnreadCount(channels: 0, messages: 0, threads: 0)

    /// The number of channels with unread messages.
    public let channels: Int

    /// The number of unread messages across all channels.
    public let messages: Int

    /// The number of threads with unread replies if available.
    public let threads: Int?

    init(channels: Int, messages: Int, threads: Int?) {
        self.channels = channels
        self.messages = messages
        self.threads = threads
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let channels = try container.decodeIfPresent(Int.self, forKey: .channels),
           let messages = try container.decodeIfPresent(Int.self, forKey: .messages) {
            self.channels = channels
            self.messages = messages
            threads = try container.decodeIfPresent(Int.self, forKey: .threads)
        } else if let currentUserUnreadCount = try container.decodeIfPresent(UnreadCount.self, forKey: .currentUserUnreadCount) {
            channels = currentUserUnreadCount.channels
            messages = currentUserUnreadCount.messages
            threads = currentUserUnreadCount.threads
        } else if let userUnreadCount = try container.decodeIfPresent(UnreadCount.self, forKey: .userUnreadCount) {
            channels = userUnreadCount.channels
            messages = userUnreadCount.messages
            threads = userUnreadCount.threads
        } else {
            throw ClientError.EventDecoding(missingValue: "unread_channels, total_unread_count", for: Self.self)
        }
    }
}
