//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

struct ChannelListPayload {
    /// A list of channels response (see `ChannelQuery`).
    let channels: [ChannelPayload]
}

extension ChannelListPayload: Decodable {
    enum CodingKeys: String, CodingKey {
        case channels
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let channels = try container
            .decodeArrayIgnoringFailures([ChannelPayload].self, forKey: .channels)

        self.init(
            channels: channels
        )
    }
}

struct ChannelPayload {
    let channel: ChannelDetailPayload

    let watcherCount: Int?

    let watchers: [UserPayload]?

    let members: [MemberPayload]

    let membership: MemberPayload?

    let messages: [MessagePayload]

    let pinnedMessages: [MessagePayload]

    let channelReads: [ChannelReadPayload]

    let isHidden: Bool?
}

extension ChannelPayload {
    /// Returns the newest message from `messages` in O(1) assuming messages are sorted by `createdAt`.
    var newestMessage: MessagePayload? {
        guard let first = messages.first, let last = messages.last else { return nil }

        return first.createdAt > last.createdAt ? first : last
    }
}

extension ChannelPayload: Decodable {
    enum CodingKeys: String, CodingKey {
        case channel
        case messages
        case pinnedMessages = "pinned_messages"
        case channelReads = "read"
        case members
        case watchers
        case membership
        case watcherCount = "watcher_count"
        case hidden
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.init(
            channel: try container.decode(ChannelDetailPayload.self, forKey: .channel),
            watcherCount: try container.decodeIfPresent(Int.self, forKey: .watcherCount),
            watchers: try container.decodeArrayIfPresentIgnoringFailures([UserPayload].self, forKey: .watchers),
            members: try container.decodeArrayIgnoringFailures([MemberPayload].self, forKey: .members),
            membership: try container.decodeIfPresent(MemberPayload.self, forKey: .membership),
            messages: try container.decodeArrayIgnoringFailures([MessagePayload].self, forKey: .messages),
            pinnedMessages: try container.decodeArrayIgnoringFailures([MessagePayload].self, forKey: .pinnedMessages),
            channelReads: try container.decodeArrayIfPresentIgnoringFailures([ChannelReadPayload].self, forKey: .channelReads) ?? [],
            isHidden: try container.decodeIfPresent(Bool.self, forKey: .hidden)
        )
    }
}

struct ChannelDetailPayload {
    let cid: ChannelId

    let name: String?

    let imageURL: URL?

    let extraData: [String: RawJSON]

    /// A channel type.
    let typeRawValue: String

    /// The last message date.
    let lastMessageAt: Date?
    /// A channel created date.
    let createdAt: Date
    /// A channel deleted date.
    let deletedAt: Date?
    /// A channel updated date.
    let updatedAt: Date
    /// A channel truncated date.
    let truncatedAt: Date?

    /// A creator of the channel.
    let createdBy: UserPayload?
    /// A config.
    let config: ChannelConfig
    /// The list of actions that the current user can perform in a channel.
    /// It is optional, since not all events contain the own capabilities property for performance reasons.
    let ownCapabilities: [String]?
    /// Checks if the channel is frozen.
    let isFrozen: Bool

    /// Checks if the channel is hidden.
    /// Backend only sends this field for `QueryChannel` and `QueryChannels` API calls,
    /// but not for events.
    /// Missing `hidden` field doesn't mean `false` for this reason.
    let isHidden: Bool?

    let members: [MemberPayload]?

    let memberCount: Int

    /// A list of users to invite in the channel.
    let invitedMembers: [MemberPayload] = [] // TODO?

    /// The team the channel belongs to. You need to enable multi-tenancy if you want to use this, else it'll be nil.
    /// Refer to [docs](https://getstream.io/chat/docs/multi_tenant_chat/?language=swift) for more info.
    let team: TeamId?

    /// Cooldown duration for the channel, if it's in slow mode.
    /// This value will be 0 if the channel is not in slow mode.
    let cooldownDuration: Int
}

extension ChannelDetailPayload: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ChannelCodingKeys.self)

        let extraData: [String: RawJSON]
        if var payload = try? [String: RawJSON](from: decoder) {
            payload.removeValues(forKeys: ChannelCodingKeys.allCases.map(\.rawValue))
            extraData = payload
        } else {
            extraData = [:]
        }

        self.init(
            cid: try container.decode(ChannelId.self, forKey: .cid),
            name: try container.decodeIfPresent(String.self, forKey: .name),
            // Unfortunately, the built-in URL decoder fails, if the string is empty. We need to
            // provide custom decoding to handle URL? as expected.
            imageURL: try container.decodeIfPresent(String.self, forKey: .imageURL).flatMap(URL.init(string:)),
            extraData: extraData,
            typeRawValue: try container.decode(String.self, forKey: .typeRawValue),
            lastMessageAt: try container.decodeIfPresent(Date.self, forKey: .lastMessageAt),
            createdAt: try container.decode(Date.self, forKey: .createdAt),
            deletedAt: try container.decodeIfPresent(Date.self, forKey: .deletedAt),
            updatedAt: try container.decode(Date.self, forKey: .updatedAt),
            truncatedAt: try container.decodeIfPresent(Date.self, forKey: .truncatedAt),
            createdBy: try container.decodeIfPresent(UserPayload.self, forKey: .createdBy),
            config: try container.decode(ChannelConfig.self, forKey: .config),
            ownCapabilities: try container.decodeIfPresent([String].self, forKey: .ownCapabilities),
            isFrozen: try container.decode(Bool.self, forKey: .frozen),
            // For `hidden`, we don't fallback to `false`
            // since this field is not sent for all API calls and for events
            // We can't assume anything regarding this flag when it's absent
            isHidden: try container.decodeIfPresent(Bool.self, forKey: .hidden),
            members: try container.decodeArrayIfPresentIgnoringFailures([MemberPayload].self, forKey: .members),
            memberCount: try container.decodeIfPresent(Int.self, forKey: .memberCount) ?? 0,
            team: try container.decodeIfPresent(String.self, forKey: .team),
            cooldownDuration: try container.decodeIfPresent(Int.self, forKey: .cooldownDuration) ?? 0
        )
    }
}

struct ChannelReadPayload: Decodable {
    private enum CodingKeys: String, CodingKey {
        case user
        case lastReadAt = "last_read"
        case lastReadMessageId = "last_read_message_id"
        case unreadMessagesCount = "unread_messages"
    }

    /// A user (see `User`).
    let user: UserPayload
    /// A last read date by the user.
    public let lastReadAt: Date
    /// Id for the last message the user has read. Nil means the user has never read this channel
    public let lastReadMessageId: MessageId?
    /// Unread message count for the user.
    public let unreadMessagesCount: Int
}
