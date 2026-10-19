//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChannelGetOrCreateRequest: Sendable, Encodable, JSONEncodable {
    let data: ChannelInput?
    /// Adds scheduled_messages to the response: the caller's own scheduled, sending and failed messages in this channel. Client-side only. Absent from the response when there are more than 100 or they could not be loaded; use the scheduled messages query then
    let includeScheduledMessages: Bool?
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
        includeScheduledMessages: Bool? = nil,
        members: PaginationParams? = nil,
        messages: MessagePaginationParams? = nil,
        presence: Bool? = nil,
        state: Bool? = nil,
        watch: Bool? = nil,
        watchers: PaginationParams? = nil
    ) {
        self.data = data
        self.includeScheduledMessages = includeScheduledMessages
        self.members = members
        self.messages = messages
        self.presence = presence
        self.state = state
        self.watch = watch
        self.watchers = watchers
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encodeIfPresent(includeScheduledMessages, forKey: .includeScheduledMessages)
        try container.encodeIfPresent(members, forKey: .members)
        try container.encodeIfPresent(messages, forKey: .messages)
        try container.encodeIfPresent(presence, forKey: .presence)
        try container.encodeIfPresent(state, forKey: .state)
        try container.encodeIfPresent(watch, forKey: .watch)
        try container.encodeIfPresent(watchers, forKey: .watchers)
    }
}
