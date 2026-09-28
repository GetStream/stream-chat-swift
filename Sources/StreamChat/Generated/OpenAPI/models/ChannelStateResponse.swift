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
    let members: [MemberPayload]
    let membership: MemberPayload?
    let messages: [MessageResponse]
    let pendingMessages: [PendingMessageResponse]?
    let pinnedMessages: [MessageResponse]
    let pushPreferences: PushPreference?
    let read: [ReadStateResponse]?
    let threads: [ThreadStateResponse]
    let watcherCount: Int?
    let watchers: [UserPayload]?

    init(
        activeLiveLocations: [SharedLocation]? = nil,
        channel: ChannelDetailPayload,
        draft: DraftPayload? = nil,
        hidden: Bool? = nil,
        members: [MemberPayload],
        membership: MemberPayload? = nil,
        messages: [MessageResponse],
        pendingMessages: [PendingMessageResponse]? = nil,
        pinnedMessages: [MessageResponse],
        pushPreferences: PushPreference? = nil,
        read: [ReadStateResponse]? = nil,
        threads: [ThreadStateResponse],
        watcherCount: Int? = nil,
        watchers: [UserPayload]? = nil
    ) {
        self.activeLiveLocations = activeLiveLocations
        self.channel = channel
        self.draft = draft
        self.hidden = hidden
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
}
