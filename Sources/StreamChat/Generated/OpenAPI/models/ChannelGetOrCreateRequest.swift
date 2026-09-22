//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChannelGetOrCreateRequest: Sendable, Encodable, JSONEncodable {
    let data: ChannelInput?
    /// Top-level keys of the message sender's channel-member custom data to include under member.custom (max 8 keys, 64 chars each)
    let memberCustomInclude: [String]?
    let members: PaginationParams?
    let messages: MessagePaginationParams?
    /// Fetch user presence info
    let presence: Bool?
    /// Refresh channel state
    let state: Bool?
    let threadUnreadCounts: Bool?
    /// Start watching the channel
    let watch: Bool?
    let watchers: PaginationParams?

    init(
        data: ChannelInput? = nil,
        memberCustomInclude: [String]? = nil,
        members: PaginationParams? = nil,
        messages: MessagePaginationParams? = nil,
        presence: Bool? = nil,
        state: Bool? = nil,
        threadUnreadCounts: Bool? = nil,
        watch: Bool? = nil,
        watchers: PaginationParams? = nil
    ) {
        self.data = data
        self.memberCustomInclude = memberCustomInclude
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
        case memberCustomInclude = "member_custom_include"
        case members
        case messages
        case presence
        case state
        case threadUnreadCounts = "thread_unread_counts"
        case watch
        case watchers
    }
}
