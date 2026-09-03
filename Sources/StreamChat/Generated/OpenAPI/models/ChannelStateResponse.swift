//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChannelStateResponse: Sendable, Decodable {
    let activeLiveLocations: [SharedLocation]?
    /// Represents channel in chat
    let channel: ChannelDetailPayload
    let draft: DraftPayload?
    let hidden: Bool?
    let hideMessagesBefore: Date?
    let members: [MemberPayload]
    let membership: MemberPayload?
    let messages: [MessageResponse]
    let pendingMessages: [PendingMessageResponse]?
    let pinnedMessages: [MessageResponse]
    let pushPreferences: PushPreference?
    let read: [ReadStateResponse]?
    let watcherCount: Int?
    let watchers: [UserPayload]?

    init(
        activeLiveLocations: [SharedLocation]? = nil,
        channel: ChannelDetailPayload,
        draft: DraftPayload? = nil,
        hidden: Bool? = nil,
        hideMessagesBefore: Date? = nil,
        members: [MemberPayload],
        membership: MemberPayload? = nil,
        messages: [MessageResponse],
        pendingMessages: [PendingMessageResponse]? = nil,
        pinnedMessages: [MessageResponse],
        pushPreferences: PushPreference? = nil,
        read: [ReadStateResponse]? = nil,
        watcherCount: Int? = nil,
        watchers: [UserPayload]? = nil
    ) {
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
        case watcherCount = "watcher_count"
        case watchers
    }
}
