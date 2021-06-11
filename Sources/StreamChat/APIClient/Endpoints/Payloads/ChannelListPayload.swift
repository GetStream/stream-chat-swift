//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

struct ChannelListPayload<ExtraData: ExtraDataTypes>: Decodable {
    /// A list of channels response (see `ChannelQuery`).
    let channels: [ChannelPayload<ExtraData>]
}

struct ChannelPayload<ExtraData: ExtraDataTypes>: Decodable {
    let channel: ChannelDetailPayload<ExtraData>
    
    let watcherCount: Int?
    
    let watchers: [UserPayload<ExtraData.User>]?
    
    let members: [MemberPayload<ExtraData.User>]

    let membership: MemberPayload<ExtraData.User>?

    let messages: [MessagePayload<ExtraData>]

    let pinnedMessages: [MessagePayload<ExtraData>]
    
    let channelReads: [ChannelReadPayload<ExtraData>]

    private enum CodingKeys: String, CodingKey {
        case channel
        case messages
        case pinnedMessages = "pinned_messages"
        case channelReads = "read"
        case members
        case watchers
        case membership
        case watcherCount = "watcher_count"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        channel = try container.decode(ChannelDetailPayload<ExtraData>.self, forKey: .channel)
        watchers = try container.decodeIfPresent([UserPayload<ExtraData.User>].self, forKey: .watchers)
        watcherCount = try container.decodeIfPresent(Int.self, forKey: .watcherCount)
        members = try container.decode([MemberPayload<ExtraData.User>].self, forKey: .members)
        membership = try container.decodeIfPresent(MemberPayload<ExtraData.User>.self, forKey: .membership)
        messages = try container.decode([MessagePayload<ExtraData>].self, forKey: .messages)
        pinnedMessages = try container.decode([MessagePayload<ExtraData>].self, forKey: .pinnedMessages)
        channelReads = try container.decodeIfPresent([ChannelReadPayload<ExtraData>].self, forKey: .channelReads) ?? []
    }
    
    // MARK: - For testing
    
    init(
        channel: ChannelDetailPayload<ExtraData>,
        watcherCount: Int,
        watchers: [UserPayload<ExtraData.User>]?,
        members: [MemberPayload<ExtraData.User>],
        membership: MemberPayload<ExtraData.User>?,
        messages: [MessagePayload<ExtraData>],
        pinnedMessages: [MessagePayload<ExtraData>],
        channelReads: [ChannelReadPayload<ExtraData>]
    ) {
        self.channel = channel
        self.watcherCount = watcherCount
        self.watchers = watchers
        self.members = members
        self.membership = membership
        self.messages = messages
        self.pinnedMessages = pinnedMessages
        self.channelReads = channelReads
    }
}

struct ChannelDetailPayload<ExtraData: ExtraDataTypes>: Decodable {
    let cid: ChannelId
    
    let name: String?
    
    let imageURL: URL?
    
    let extraData: ExtraData.Channel
    
    /// A channel type.
    public let typeRawValue: String
    
    /// The last message date.
    public let lastMessageAt: Date?
    /// A channel created date.
    public let createdAt: Date
    /// A channel deleted date.
    public let deletedAt: Date?
    /// A channel updated date.
    public let updatedAt: Date
    
    /// A creator of the channel.
    public let createdBy: UserPayload<ExtraData.User>?
    /// A config.
    public let config: ChannelConfig
    /// Checks if the channel is frozen.
    public let isFrozen: Bool
    
    let members: [MemberPayload<ExtraData.User>]?
    
    let memberCount: Int
    
    /// A list of users to invite in the channel.
    let invitedMembers: [MemberPayload<ExtraData.User>] = [] // TODO?
    
    /// The team the channel belongs to. You need to enable multi-tenancy if you want to use this, else it'll be nil.
    /// Refer to [docs](https://getstream.io/chat/docs/multi_tenant_chat/?language=swift) for more info.
    public let team: TeamId?
    
    /// Cooldown duration for the channel, if it's in slow mode.
    /// This value will be 0 if the channel is not in slow mode.
    let cooldownDuration: Int
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ChannelCodingKeys.self)
        typeRawValue = try container.decode(String.self, forKey: .typeRawValue)
        cid = try container.decode(ChannelId.self, forKey: .cid)
        // Unfortunately, the built-in URL decoder fails, if the string is empty. We need to
        // provide custom decoding to handle URL? as expected.
        name = try container.decodeIfPresent(String.self, forKey: .name)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL).flatMap(URL.init(string:))
        let config = try container.decode(ChannelConfig.self, forKey: .config)
        self.config = config
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        createdBy = try container.decodeIfPresent(UserPayload<ExtraData.User>.self, forKey: .createdBy)
        lastMessageAt = try container.decodeIfPresent(Date.self, forKey: .lastMessageAt)
        isFrozen = try container.decode(Bool.self, forKey: .frozen)
        team = try container.decodeIfPresent(String.self, forKey: .team)
        memberCount = try container.decodeIfPresent(Int.self, forKey: .memberCount) ?? 0
        
        members = try container.decodeIfPresent([MemberPayload<ExtraData.User>].self, forKey: .members)
        
        cooldownDuration = try container.decodeIfPresent(Int.self, forKey: .cooldownDuration) ?? 0
        
        extraData = try ExtraData.Channel(from: decoder)
    }
    
    // MARK: - For testing
    
    internal init(
        cid: ChannelId,
        name: String?,
        imageURL: URL?,
        extraData: ExtraData.Channel,
        typeRawValue: String,
        lastMessageAt: Date?,
        createdAt: Date,
        deletedAt: Date?,
        updatedAt: Date,
        createdBy: UserPayload<ExtraData.User>?,
        config: ChannelConfig,
        isFrozen: Bool,
        memberCount: Int,
        team: String?,
        members: [MemberPayload<ExtraData.User>]?,
        cooldownDuration: Int
    ) {
        self.cid = cid
        self.name = name
        self.imageURL = imageURL
        self.extraData = extraData
        self.typeRawValue = typeRawValue
        self.lastMessageAt = lastMessageAt
        self.createdAt = createdAt
        self.deletedAt = deletedAt
        self.updatedAt = updatedAt
        self.createdBy = createdBy
        self.config = config
        self.isFrozen = isFrozen
        self.memberCount = memberCount
        self.team = team
        self.members = members
        self.cooldownDuration = cooldownDuration
    }
}

struct ChannelReadPayload<ExtraData: ExtraDataTypes>: Decodable {
    private enum CodingKeys: String, CodingKey {
        case user
        case lastReadAt = "last_read"
        case unreadMessagesCount = "unread_messages"
    }
    
    /// A user (see `User`).
    let user: UserPayload<ExtraData.User>
    /// A last read date by the user.
    public let lastReadAt: Date
    /// Unread message count for the user.
    public let unreadMessagesCount: Int
    
//    /// Init a message read.
//    ///
//    /// - Parameters:
//    ///   - user: a user.
//    ///   - lastReadDate: the last read date.
//    ///   - unreadMessages: Unread message count
//    init(user: UserPayload<ExtraData.User>, lastReadDate: Date, unreadMessagesCount: Int) {
//        self.user = user
//        self.lastReadDate = lastReadDate
//        self.unreadMessagesCount = unreadMessagesCount
//    }
}

/// A channel config.
public struct ChannelConfig: Codable {
    private enum CodingKeys: String, CodingKey {
        case reactionsEnabled = "reactions"
        case typingEventsEnabled = "typing_events"
        case readEventsEnabled = "read_events"
        case connectEventsEnabled = "connect_events"
        case uploadsEnabled = "uploads"
        case repliesEnabled = "replies"
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
    
    /// Determines if users are able to flag messages. Enabled by default.
    public var flagsEnabled: Bool { commands.map(\.name).contains("flag") }
        
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reactionsEnabled = try container.decode(Bool.self, forKey: .reactionsEnabled)
        typingEventsEnabled = try container.decode(Bool.self, forKey: .typingEventsEnabled)
        readEventsEnabled = try container.decode(Bool.self, forKey: .readEventsEnabled)
        connectEventsEnabled = try container.decode(Bool.self, forKey: .connectEventsEnabled)
        uploadsEnabled = try container.decodeIfPresent(Bool.self, forKey: .uploadsEnabled) ?? false
        repliesEnabled = try container.decode(Bool.self, forKey: .repliesEnabled)
        searchEnabled = try container.decode(Bool.self, forKey: .searchEnabled)
        mutesEnabled = try container.decode(Bool.self, forKey: .mutesEnabled)
        urlEnrichmentEnabled = try container.decode(Bool.self, forKey: .urlEnrichmentEnabled)
        messageRetention = try container.decode(String.self, forKey: .messageRetention)
        maxMessageLength = try container.decode(Int.self, forKey: .maxMessageLength)
        commands = try container.decodeIfPresent([Command].self, forKey: .commands) ?? []
        
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    internal init(
        reactionsEnabled: Bool = false,
        typingEventsEnabled: Bool = false,
        readEventsEnabled: Bool = false,
        connectEventsEnabled: Bool = false,
        uploadsEnabled: Bool = false,
        repliesEnabled: Bool = false,
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
