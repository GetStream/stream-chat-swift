//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChannelGetOrCreateRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var data: ChannelInput?
    /// Whether this channel will be hidden for the user who created the channel or not
    var hideForCreator: Bool?
    var members: PaginationParams?
    var messages: MessagePaginationParams?
    /// Fetch user presence info
    var presence: Bool?
    /// Refresh channel state
    var state: Bool?
    var threadUnreadCounts: Bool?
    /// Start watching the channel
    var watch: Bool?
    var watchers: PaginationParams?

    init(data: ChannelInput? = nil, hideForCreator: Bool? = nil, members: PaginationParams? = nil, messages: MessagePaginationParams? = nil, presence: Bool? = nil, state: Bool? = nil, threadUnreadCounts: Bool? = nil, watch: Bool? = nil, watchers: PaginationParams? = nil) {
        self.data = data
        self.hideForCreator = hideForCreator
        self.members = members
        self.messages = messages
        self.presence = presence
        self.state = state
        self.threadUnreadCounts = threadUnreadCounts
        self.watch = watch
        self.watchers = watchers
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case data
        case hideForCreator = "hide_for_creator"
        case members
        case messages
        case presence
        case state
        case threadUnreadCounts = "thread_unread_counts"
        case watch
        case watchers
    }

    static func == (lhs: ChannelGetOrCreateRequest, rhs: ChannelGetOrCreateRequest) -> Bool {
        lhs.data == rhs.data &&
            lhs.hideForCreator == rhs.hideForCreator &&
            lhs.members == rhs.members &&
            lhs.messages == rhs.messages &&
            lhs.presence == rhs.presence &&
            lhs.state == rhs.state &&
            lhs.threadUnreadCounts == rhs.threadUnreadCounts &&
            lhs.watch == rhs.watch &&
            lhs.watchers == rhs.watchers
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(data)
        hasher.combine(hideForCreator)
        hasher.combine(members)
        hasher.combine(messages)
        hasher.combine(presence)
        hasher.combine(state)
        hasher.combine(threadUnreadCounts)
        hasher.combine(watch)
        hasher.combine(watchers)
    }
}
