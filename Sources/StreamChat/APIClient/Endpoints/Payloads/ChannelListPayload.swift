//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

struct ChannelListPayload: Decodable {
    /// A list of channels response (see `ChannelQuery`).
    let channels: [ChannelPayload]
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

extension ChannelPayload: Decodable {
    private enum CodingKeys: String, CodingKey {
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
            watchers: try container.decodeIfPresent([UserPayload].self, forKey: .watchers),
            members: try container.decode([MemberPayload].self, forKey: .members),
            membership: try container.decodeIfPresent(MemberPayload.self, forKey: .membership),
            messages: try container.decode([MessagePayload].self, forKey: .messages),
            pinnedMessages: try container.decode([MessagePayload].self, forKey: .pinnedMessages),
            channelReads: try container.decodeIfPresent([ChannelReadPayload].self, forKey: .channelReads) ?? [],
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
            isFrozen: try container.decode(Bool.self, forKey: .frozen),
            // For `hidden`, we don't fallback to `false`
            // since this field is not sent for all API calls and for events
            // We can't assume anything regarding this flag when it's absent
            isHidden: try container.decodeIfPresent(Bool.self, forKey: .hidden),
            members: try container.decodeIfPresent([MemberPayload].self, forKey: .members),
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
        case unreadMessagesCount = "unread_messages"
    }
    
    /// A user (see `User`).
    let user: UserPayload
    /// A last read date by the user.
    public let lastReadAt: Date
    /// Unread message count for the user.
    public let unreadMessagesCount: Int
}

/// A channel config.
public class ChannelConfig: Codable {
    private enum CodingKeys: String, CodingKey {
        case reactionsEnabled = "reactions"
        case typingEventsEnabled = "typing_events"
        case readEventsEnabled = "read_events"
        case connectEventsEnabled = "connect_events"
        case uploadsEnabled = "uploads"
        case repliesEnabled = "replies"
        case quotesEnabled = "quotes"
        case searchEnabled = "search"
        case mutesEnabled = "mutes"
        case urlEnrichmentEnabled = "url_enrichment"
        case messageRetention = "message_retention"
        case maxMessageLength = "max_message_length"
        case commands
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// If users are allowed to add reactions to messages. Enabled by default.
    public let reactionsEnabled: Bool
    /// Controls if typing indicators are shown. Enabled by default.
    public let typingEventsEnabled: Bool
    /// Controls whether the chat shows how far you’ve read. Enabled by default.
    public let readEventsEnabled: Bool
    /// Determines if events are fired for connecting and disconnecting to a chat. Enabled by default.
    public let connectEventsEnabled: Bool
    /// Enables uploads.
    public let uploadsEnabled: Bool
    /// Enables message thread replies. Enabled by default.
    public let repliesEnabled: Bool
    /// Enables quoting of messages. Enabled by default.
    public let quotesEnabled: Bool
    /// Controls if messages should be searchable (this is a premium feature). Disabled by default.
    public let searchEnabled: Bool
    /// Determines if users are able to mute other users. Enabled by default.
    public let mutesEnabled: Bool
    /// Determines if URL enrichment enabled to show they as attachments. Enabled by default.
    public let urlEnrichmentEnabled: Bool
    /// A number of days or infinite. Infinite by default.
    public let messageRetention: String
    /// The max message length. 5000 by default.
    public let maxMessageLength: Int
    /// An array of commands, e.g. /giphy.
    public let commands: [Command]
    /// A channel created date.
    public let createdAt: Date
    /// A channel updated date.
    public let updatedAt: Date
        
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reactionsEnabled = try container.decode(Bool.self, forKey: .reactionsEnabled)
        typingEventsEnabled = try container.decode(Bool.self, forKey: .typingEventsEnabled)
        readEventsEnabled = try container.decode(Bool.self, forKey: .readEventsEnabled)
        connectEventsEnabled = try container.decode(Bool.self, forKey: .connectEventsEnabled)
        uploadsEnabled = try container.decodeIfPresent(Bool.self, forKey: .uploadsEnabled) ?? false
        repliesEnabled = try container.decode(Bool.self, forKey: .repliesEnabled)
        quotesEnabled = try container.decode(Bool.self, forKey: .quotesEnabled)
        searchEnabled = try container.decode(Bool.self, forKey: .searchEnabled)
        mutesEnabled = try container.decode(Bool.self, forKey: .mutesEnabled)
        urlEnrichmentEnabled = try container.decode(Bool.self, forKey: .urlEnrichmentEnabled)
        messageRetention = try container.decode(String.self, forKey: .messageRetention)
        maxMessageLength = try container.decode(Int.self, forKey: .maxMessageLength)
        let commands = try container.decodeIfPresent([Command].self, forKey: .commands) ?? []
        // We exclude the flag commands since it's not implemented by backend
        // and it'll be removed soon.
        // TODO: Remove this line of code when backend stops sending the `flag` command
        self.commands = commands.filter { $0.name != "flag" }
        
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    internal required init(
        reactionsEnabled: Bool = false,
        typingEventsEnabled: Bool = false,
        readEventsEnabled: Bool = false,
        connectEventsEnabled: Bool = false,
        uploadsEnabled: Bool = false,
        repliesEnabled: Bool = false,
        quotesEnabled: Bool = false,
        searchEnabled: Bool = false,
        mutesEnabled: Bool = false,
        urlEnrichmentEnabled: Bool = false,
        messageRetention: String = "",
        maxMessageLength: Int = 0,
        commands: [Command] = [],
        createdAt: Date = .init(),
        updatedAt: Date = .init()
    ) {
        self.reactionsEnabled = reactionsEnabled
        self.typingEventsEnabled = typingEventsEnabled
        self.readEventsEnabled = readEventsEnabled
        self.connectEventsEnabled = connectEventsEnabled
        self.uploadsEnabled = uploadsEnabled
        self.repliesEnabled = repliesEnabled
        self.quotesEnabled = quotesEnabled
        self.searchEnabled = searchEnabled
        self.mutesEnabled = mutesEnabled
        self.urlEnrichmentEnabled = urlEnrichmentEnabled
        self.messageRetention = messageRetention
        self.maxMessageLength = maxMessageLength
        self.commands = commands
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
