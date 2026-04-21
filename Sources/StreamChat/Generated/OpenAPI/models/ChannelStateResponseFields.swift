//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChannelStateResponseFields: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Active live locations in the channel
    var activeLiveLocations: [SharedLocationResponseData]?
    var channel: ChannelResponse?
    var draft: DraftResponse?
    /// Whether this channel is hidden or not
    var hidden: Bool?
    /// Messages before this date are hidden from the user
    var hideMessagesBefore: Date?
    /// List of channel members
    var members: [ChannelMemberResponse]
    var membership: ChannelMemberResponse?
    /// List of channel messages
    var messages: [MessageResponse]
    /// Pending messages that this user has sent
    var pendingMessages: [PendingMessageResponse]?
    /// List of pinned messages in the channel
    var pinnedMessages: [MessageResponse]
    var pushPreferences: ChannelPushPreferencesResponse?
    /// List of read states
    var read: [ReadStateResponse]?
    var threads: [ThreadStateResponse]
    /// Number of channel watchers
    var watcherCount: Int?
    /// List of user who is watching the channel
    var watchers: [UserResponse]?

    init(activeLiveLocations: [SharedLocationResponseData]? = nil, channel: ChannelResponse? = nil, draft: DraftResponse? = nil, hidden: Bool? = nil, hideMessagesBefore: Date? = nil, members: [ChannelMemberResponse], membership: ChannelMemberResponse? = nil, messages: [MessageResponse], pendingMessages: [PendingMessageResponse]? = nil, pinnedMessages: [MessageResponse], pushPreferences: ChannelPushPreferencesResponse? = nil, read: [ReadStateResponse]? = nil, threads: [ThreadStateResponse], watcherCount: Int? = nil, watchers: [UserResponse]? = nil) {
        self.activeLiveLocations = activeLiveLocations
        self.channel = channel
        self.draft = draft
        self.hidden = hidden
        self.hideMessagesBefore = hideMessagesBefore
        self.members = members
        self.membership = membership
        self.messages = messages
        self.pendingMessages = pendingMessages
        self.pinnedMessages = pinnedMessages
        self.pushPreferences = pushPreferences
        self.read = read
        self.threads = threads
        self.watcherCount = watcherCount
        self.watchers = watchers
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case activeLiveLocations = "active_live_locations"
        case channel
        case draft
        case hidden
        case hideMessagesBefore = "hide_messages_before"
        case members
        case membership
        case messages
        case pendingMessages = "pending_messages"
        case pinnedMessages = "pinned_messages"
        case pushPreferences = "push_preferences"
        case read
        case threads
        case watcherCount = "watcher_count"
        case watchers
    }

    static func == (lhs: ChannelStateResponseFields, rhs: ChannelStateResponseFields) -> Bool {
        lhs.activeLiveLocations == rhs.activeLiveLocations &&
            lhs.channel == rhs.channel &&
            lhs.draft == rhs.draft &&
            lhs.hidden == rhs.hidden &&
            lhs.hideMessagesBefore == rhs.hideMessagesBefore &&
            lhs.members == rhs.members &&
            lhs.membership == rhs.membership &&
            lhs.messages == rhs.messages &&
            lhs.pendingMessages == rhs.pendingMessages &&
            lhs.pinnedMessages == rhs.pinnedMessages &&
            lhs.pushPreferences == rhs.pushPreferences &&
            lhs.read == rhs.read &&
            lhs.threads == rhs.threads &&
            lhs.watcherCount == rhs.watcherCount &&
            lhs.watchers == rhs.watchers
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(activeLiveLocations)
        hasher.combine(channel)
        hasher.combine(draft)
        hasher.combine(hidden)
        hasher.combine(hideMessagesBefore)
        hasher.combine(members)
        hasher.combine(membership)
        hasher.combine(messages)
        hasher.combine(pendingMessages)
        hasher.combine(pinnedMessages)
        hasher.combine(pushPreferences)
        hasher.combine(read)
        hasher.combine(threads)
        hasher.combine(watcherCount)
        hasher.combine(watchers)
    }
}
