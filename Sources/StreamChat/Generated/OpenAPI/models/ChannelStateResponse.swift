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
    let threads: [ThreadStateResponse]
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
        threads: [ThreadStateResponse],
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        activeLiveLocations = try container.decodeArrayIfPresentIgnoringFailures(
            [SharedLocation].self,
            forKey: .activeLiveLocations
        )
        channel = try container.decode(ChannelDetailPayload.self, forKey: .channel)
        draft = try container.decodeIfPresent(DraftPayload.self, forKey: .draft)
        hidden = try container.decodeIfPresent(Bool.self, forKey: .hidden)
        hideMessagesBefore = try container.decodeIfPresent(Date.self, forKey: .hideMessagesBefore)
        members = try container.decodeArrayIgnoringFailures([MemberPayload].self, forKey: .members)
        membership = try container.decodeIfPresent(MemberPayload.self, forKey: .membership)
        messages = try container.decodeArrayIgnoringFailures(
            [MessageResponse].self,
            forKey: .messages
        )
        pendingMessages = try container.decodeArrayIfPresentIgnoringFailures(
            [PendingMessageResponse].self,
            forKey: .pendingMessages
        )
        pinnedMessages = try container.decodeArrayIgnoringFailures(
            [MessageResponse].self,
            forKey: .pinnedMessages
        )
        pushPreferences = try container.decodeIfPresent(
            PushPreference.self,
            forKey: .pushPreferences
        )
        read = try container.decodeArrayIfPresentIgnoringFailures(
            [ReadStateResponse].self,
            forKey: .read
        )
        threads = try container.decodeArrayIfPresentIgnoringFailures(
            [ThreadStateResponse].self,
            forKey: .threads
        ) ?? []
        watcherCount = try container.decodeIfPresent(Int.self, forKey: .watcherCount)
        watchers = try container.decodeArrayIfPresentIgnoringFailures(
            [UserPayload].self,
            forKey: .watchers
        )
    }
}
