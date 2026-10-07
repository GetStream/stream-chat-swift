//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChannelGetOrCreateRequest: Sendable, Encodable, JSONEncodable {
    let data: ChannelInput?
    let members: PaginationParams?
    let messages: MessagePaginationParams?
    /// Fetch user presence info
    let presence: Bool?
    /// Refresh channel state
    let state: Bool?
    /// Start watching the channel
    let watch: Bool?
    let watchers: PaginationParams?

    init(
        data: ChannelInput? = nil,
        members: PaginationParams? = nil,
        messages: MessagePaginationParams? = nil,
        presence: Bool? = nil,
        state: Bool? = nil,
        watch: Bool? = nil,
        watchers: PaginationParams? = nil
    ) {
        self.data = data
        self.members = members
        self.messages = messages
        self.presence = presence
        self.state = state
        self.watch = watch
        self.watchers = watchers
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case data
        case members
        case messages
        case presence
        case state
        case watch
        case watchers
    }
}
