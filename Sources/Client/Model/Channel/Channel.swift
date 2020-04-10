//
//  Channel.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A Channel class.
public final class Channel: Codable {
    /// Coding keys for the decoding.
    public enum DecodingKeys: String, CodingKey {
        /// An channel id.
        case id
        /// A combination of channel id and type.
        case cid
        /// A type.
        case type
        /// A last message date.
        case lastMessageDate = "last_message_at"
        /// A user created by.
        case createdBy = "created_by"
        /// A created date.
        case created = "created_at"
        /// A deleted date.
        case deleted = "deleted_at"
        /// A channel config.
        case config
        /// A frozen flag.
        case frozen
        /// A name.
        case name
        /// A image URL.
        case imageURL = "image"
        /// Members.
        case members
    }
    
    /// Coding keys for the encoding.
    enum EncodingKeys: String, CodingKey {
        case name
        case imageURL = "image"
        case members
        case invites
    }
    
    /// A custom extra data type for channels.
    /// - Note: Use this variable to setup your own extra data type for decoding channels custom fields from JSON data.
    public static var extraDataType: ChannelExtraDataCodable.Type = ChannelExtraData.self
    
    /// A channel type.
    public let type: ChannelType
    /// A channel id.
    public let id: String
    /// A channel type + id.
    public let cid: ChannelId
    /// The last message date.
    public let lastMessageDate: Date?
    /// A channel created date.
    public let created: Date
    /// A channel deleted date.
    public let deleted: Date?
    /// A creator of the channel.
    public let createdBy: User?
    /// A config.
    public let config: Config
    /// Checks if the channel is frozen.
    public let frozen: Bool
    /// A list of channel members.
    public internal(set) var members = Set<Member>()
    /// A list of channel watchers.
    public internal(set) var watchers = Set<User>()
    /// A list of users to invite in the channel.
    let invitedMembers: Set<Member>
    /// An extra data for the channel.
    public var extraData: ChannelExtraDataCodable?
    /// Check if the channel was deleted.
    public var isDeleted: Bool { deleted != nil }
    
    /// Checks if read events evalable for the current user.
    public var readEventsEnabled: Bool {
        config.readEventsEnabled && members.contains(Member.current)
    }
    
    /// Returns the current unread count.
    public var unreadCount: ChannelUnreadCount { unreadCountAtomic.get(default: .noUnread) }
    
    private(set) lazy var unreadCountAtomic = Atomic<ChannelUnreadCount>(.noUnread) { [weak self] _, _ in
        if let self = self {
            self.onUpdate?(self)
        }
    }
    
    /// Online watchers in the channel.
    public var watcherCount: Int { watcherCountAtomic.get(default: 0) }
    
    private(set) lazy var watcherCountAtomic = Atomic(0) { [weak self] _, _ in
        if let self = self {
            self.onUpdate?(self)
        }
    }
    
    let unreadMessageReadAtomic = Atomic<MessageRead>()
    /// Unread message state for the current user.
    public var unreadMessageRead: MessageRead? { unreadMessageReadAtomic.get() }
    /// Checks if the current status of the channel is unread.
    public var isUnread: Bool { unreadCount.messages > 0 }
    
    /// An option to enable ban users.
    public var banEnabling = BanEnabling.disabled
    var bannedUsers = [User]()
    
    /// Checks if the channel is direct message type between 2 users.
    public var isDirectMessage: Bool { id.hasPrefix("!members") && members.count == 2 }
    
    /// An event when the channel was updated.
    public var onUpdate: OnUpdate<Channel>?
    
    /// Checks if the channel was decoded from a channel response.
    public let didLoad: Bool
    
    /// Checks if the channel is watching by the client.
    public var isWatching: Bool { Client.shared.isWatching(channel: self) }
    
    private var subscriptionBag = SubscriptionBag()
    
    public init(type: ChannelType,
                id: String,
                members: [User],
                invitedMembers: [User],
                extraData: ChannelExtraDataCodable?,
                created: Date,
                deleted: Date?,
                createdBy: User?,
                lastMessageDate: Date?,
                frozen: Bool,
                config: Config) {
        self.type = type
        self.id = id
        self.cid = ChannelId(type: type, id: id)
        self.members = Set(members.map({ $0.asMember }))
        self.invitedMembers = Set(invitedMembers.map({ $0.asMember }))
        self.extraData = extraData
        self.created = created
        self.deleted = deleted
        self.createdBy = createdBy
        self.lastMessageDate = lastMessageDate
        self.frozen = frozen
        self.config = config
        didLoad = false
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DecodingKeys.self)
        type = try container.decode(ChannelType.self, forKey: .type)
        let id = try container.decode(String.self, forKey: .id)
        self.id = id
        cid = try container.decode(ChannelId.self, forKey: .cid)
        let members = try container.decodeIfPresent([Member].self, forKey: .members) ?? []
        self.members = Set<Member>(members)
        invitedMembers = Set<Member>()
        extraData = try? Self.extraDataType.init(from: decoder) // swiftlint:disable:this explicit_init
        let config = try container.decode(Config.self, forKey: .config)
        self.config = config
        created = try container.decodeIfPresent(Date.self, forKey: .created) ?? config.created
        deleted = try container.decodeIfPresent(Date.self, forKey: .deleted)
        createdBy = try container.decodeIfPresent(User.self, forKey: .createdBy)
        lastMessageDate = try container.decodeIfPresent(Date.self, forKey: .lastMessageDate)
        frozen = try container.decode(Bool.self, forKey: .frozen)
        didLoad = true
    }
    
    deinit {
        subscriptionBag.cancel()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: EncodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        extraData?.encodeSafely(to: encoder, logMessage: "📦 when encoding a channel extra data")
        
        var allMembers = members
        
        if !invitedMembers.isEmpty {
            allMembers = allMembers.union(invitedMembers)
            try container.encode(invitedMembers, forKey: .invites)
        }
        
        if !allMembers.isEmpty {
            try container.encode(allMembers, forKey: .members)
        }
    }
    
    /// Resets unread counts.
    public func resetUnreadCount(messageRead: MessageRead) {
        unreadMessageReadAtomic.set(messageRead)
        unreadCountAtomic.set(.noUnread)
    }
}

extension Channel: Hashable, CustomStringConvertible {
    
    public static func == (lhs: Channel, rhs: Channel) -> Bool {
        lhs.cid == rhs.cid
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(cid)
    }
    
    public var description: String {
        let opaque: UnsafeMutableRawPointer = Unmanaged.passUnretained(self).toOpaque()
        return "Channel<\(opaque)>:\(cid):\(name ?? "<NoName>")"
    }
}

// MARK: Subscriptions

extension Channel {
    
    public func subscribe(forEvents eventTypes: Set<EventType> = EventType.channelCases,
                          _ callback: @escaping Client.OnEvent) -> Cancellable {
        if eventTypes != EventType.channelCases, !eventTypes.isStrictSubset(of: EventType.channelCases) {
            var badEvents = eventTypes
            badEvents.subtract(EventType.channelCases)
            
            let message = "The events \(badEvents) are not channel events and will never get handled by your completion handler. "
                + "Please check the documentation on event for more information."
            
            Client.shared.logger?.log(message, level: .error)
        }
        
        let subscription = Client.shared.subscribe(forEvents: eventTypes, cid: cid, callback)
        subscriptionBag.add(subscription)
        return subscription
    }
    
    public func subscribeToUnreadCount(_ callback: @escaping Client.Completion<ChannelUnreadCount>) -> Cancellable {
        let subscription = Client.shared.subscribeToUnreadCount(for: self, callback)
        subscriptionBag.add(subscription)
        return subscription
    }
    
    public func subscribeToWatcherCount(_ callback: @escaping Client.Completion<Int>) -> Cancellable {
        let subscription = Client.shared.subscribeToWatcherCount(for: self, callback)
        subscriptionBag.add(subscription)
        return subscription
    }
}

// MARK: ChannelExtraDataCodable

extension Channel {
    
    /// A channel name.
    public var name: String? {
        get {
            extraData?.name
        }
        set {
            var object: ChannelExtraDataCodable = extraData ?? ChannelExtraData()
            object.name = newValue
            extraData = object
        }
    }
    
    /// An image of the channel.
    public var imageURL: URL? {
        get {
            extraData?.imageURL
        }
        set {
            var object: ChannelExtraDataCodable = extraData ?? ChannelExtraData()
            object.imageURL = newValue
            extraData = object
        }
    }
}

// MARK: - Helpers

extension Channel {
    
    /// Check is the user is banned for the channel.
    /// - Parameter user: a user.
    public func isBanned(_ user: User) -> Bool {
        bannedUsers.contains(user)
    }
}

// MARK: - Config

public extension Channel {
    /// A channel config.
    struct Config: Decodable {
        // swiftlint:disable:next nesting
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
            case created = "created_at"
            case updated = "updated_at"
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
        /// Enables message threads and replies. Enabled by default.
        public let repliesEnabled: Bool
        /// Controls if messages should be searchable (this is a premium feature). Disabled by default.
        public let searchEnabled: Bool
        /// Determines if users are able to mute other users. Enabled by default.
        public let mutesEnabled: Bool
        /// Determines if URL enrichment enabled to show they as attachments. Enabled by default.
        public let urlEnrichmentEnabled: Bool
        /// Determines if users are able to flag messages. Enabled by default.
        public let flagsEnabled: Bool
        /// A number of days or infinite. Infinite by default.
        public let messageRetention: String
        /// The max message length. 5000 by default.
        public let maxMessageLength: Int
        /// An array of commands, e.g. /giphy.
        public let commands: [Command]
        /// A channel created date.
        public let created: Date
        /// A channel updated date.
        public let updated: Date
        
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
            flagsEnabled = commands.first(where: { $0.name.contains("flag") }) != nil
            created = try container.decode(Date.self, forKey: .created)
            updated = try container.decode(Date.self, forKey: .updated)
        }
        
        public init(reactionsEnabled: Bool = false,
                    typingEventsEnabled: Bool = false,
                    readEventsEnabled: Bool = false,
                    connectEventsEnabled: Bool = false,
                    uploadsEnabled: Bool = false,
                    repliesEnabled: Bool = false,
                    searchEnabled: Bool = false,
                    mutesEnabled: Bool = false,
                    urlEnrichmentEnabled: Bool = false,
                    flagsEnabled: Bool = false,
                    messageRetention: String = "",
                    maxMessageLength: Int = 0,
                    commands: [Command] = [],
                    created: Date = .init(),
                    updated: Date = .init()) {
            self.reactionsEnabled = reactionsEnabled
            self.typingEventsEnabled = typingEventsEnabled
            self.readEventsEnabled = readEventsEnabled
            self.connectEventsEnabled = connectEventsEnabled
            self.uploadsEnabled = uploadsEnabled
            self.repliesEnabled = repliesEnabled
            self.searchEnabled = searchEnabled
            self.mutesEnabled = mutesEnabled
            self.urlEnrichmentEnabled = urlEnrichmentEnabled
            self.flagsEnabled = flagsEnabled
            self.messageRetention = messageRetention
            self.maxMessageLength = maxMessageLength
            self.commands = commands
            self.created = created
            self.updated = updated
        }
    }
    
    /// A command in a message, e.g. /giphy.
    struct Command: Decodable, Hashable {
        /// A command name.
        public let name: String
        /// A description.
        public let description: String
        public let set: String
        /// Args for the command.
        public let args: String
        
        public init(name: String = "",
                    description: String = "",
                    set: String = "",
                    args: String = "") {
            self.name = name
            self.description = description
            self.set = set
            self.args = args
        }
        
        public static func == (lhs: Command, rhs: Command) -> Bool {
            lhs.name == rhs.name
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
        }
    }
}

// MARK: - Helpers

private extension Array where Element == Member {
    func channelName(default: String) -> String {
        if isEmpty {
            return `default`
        }
        
        guard count > 1 else {
            return self[0].user.isCurrent ? `default` : self[0].user.name
        }
        
        if count == 2 {
            return (self[0].user.isCurrent ? self[1] : self[0]).user.name
        }
        
        let notCurrentMembers = filter({ !$0.user.isCurrent })
        return "\(notCurrentMembers[0].user.name) and \(notCurrentMembers.count - 1) others"
    }
}

// MARK: - Supporting Structs

/// A message response.
public struct MessageResponse: Decodable {
    /// A message.
    public let message: Message
    /// A reaction.
    public let reaction: Reaction?
    /// Owner channel of this message. Only available when a message is queried by its `id`.
    @NestedKey
    public var channel: Channel?
    
    enum CodingKeys: String, NestableCodingKey {
        case message
        case reaction
        case channel = "message/channel"
    }
}

/// An event response.
public struct EventResponse: Decodable {
    /// An event (see `Event`).
    public let event: Event
}

/// A file upload response.
public struct FileUploadResponse: Decodable {
    /// An uploaded file URL.
    public let file: URL
}

struct HiddenChannelRequest: Encodable {
    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case clearHistory = "clear_history"
    }
    
    let userId: String
    let clearHistory: Bool
}

/// A hidden channel event response.
public struct HiddenChannelResponse: Decodable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case cid
        case clearHistory = "clear_history"
        /// A created date.
        case created = "created_at"
    }
    
    /// A channel type + id.
    public let cid: ChannelId
    /// The message history was cleared.
    public let clearHistory: Bool
    /// An event created date.
    public let created: Date
}
