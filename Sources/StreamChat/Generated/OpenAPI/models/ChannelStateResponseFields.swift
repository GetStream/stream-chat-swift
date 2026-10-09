//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChannelStateResponseFields: Sendable, Decodable {
    /// Active live locations in the channel
    let activeLiveLocations: [SharedLocation]?
    /// Represents channel in chat
    let channel: ChannelDetailPayload
    let draft: DraftPayload?
    /// Whether this channel is hidden or not
    let hidden: Bool?
    /// List of channel members
    let members: [MemberPayload]
    let membership: MemberPayload?
    /// List of channel messages
    let messages: [MessageResponse]
    /// Pending messages that this user has sent
    let pendingMessages: [PendingMessageResponse]?
    /// List of pinned messages in the channel
    let pinnedMessages: [MessageResponse]
    /// The push preference details.
    let pushPreferences: PushPreference?
    /// List of read states
    let read: [ReadStateResponse]?
    let threads: [ThreadStateResponse]
    /// Number of channel watchers
    let watcherCount: Int?
    /// List of user who is watching the channel
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.activeLiveLocations = try container.decodeArrayIfPresentIgnoringFailures(
            [SharedLocation].self,
            forKey: .activeLiveLocations
        )
        self.channel = try container.decode(ChannelDetailPayload.self, forKey: .channel)
        self.draft = try container.decodeIfPresent(DraftPayload.self, forKey: .draft)
        self.hidden = try container.decodeIfPresent(Bool.self, forKey: .hidden)
        self.members = try container.decodeArrayIgnoringFailures(
            [MemberPayload].self,
            forKey: .members
        )
        self.membership = try container.decodeIfPresent(MemberPayload.self, forKey: .membership)
        self.messages = try container.decodeArrayIgnoringFailures(
            [MessageResponse].self,
            forKey: .messages
        )
        self.pendingMessages = try container.decodeArrayIfPresentIgnoringFailures(
            [PendingMessageResponse].self,
            forKey: .pendingMessages
        )
        self.pinnedMessages = try container.decodeArrayIgnoringFailures(
            [MessageResponse].self,
            forKey: .pinnedMessages
        )
        self.pushPreferences = try container.decodeIfPresent(
            PushPreference.self,
            forKey: .pushPreferences
        )
        self.read = try container.decodeArrayIfPresentIgnoringFailures(
            [ReadStateResponse].self,
            forKey: .read
        )
        self.threads = try container.decodeArrayIfPresentIgnoringFailures(
            [ThreadStateResponse].self,
            forKey: .threads
        ) ?? []
        self.watcherCount = try container.decodeIfPresent(Int.self, forKey: .watcherCount)
        self.watchers = try container.decodeArrayIfPresentIgnoringFailures(
            [UserPayload].self,
            forKey: .watchers
        )
    }
}
