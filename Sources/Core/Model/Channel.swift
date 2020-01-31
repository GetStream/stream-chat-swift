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
    
    /// A channel id.
    public let id: String
    /// A channel type + id.
    public let cid: ChannelId
    /// A channel type.
    public let type: ChannelType
    /// A channel name.
    public internal(set) var name: String
    /// An image of the channel.
    public internal(set) var imageURL: URL?
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
    /// A list of user ids of the channel members.
    public internal(set) var members = Set<Member>()
    /// A list of users to invite in the channel.
    let invitedMembers: Set<Member>
    /// An extra data for the channel.
    public internal(set) var extraData: ExtraData?
    
    /// Check if the channel was deleted.
    public var isDeleted: Bool {
        return deleted != nil
    }
    
    private static var activeChannelIds: [ChannelId] = []
    
    var isActive: Bool {
        return Channel.activeChannelIds.contains(cid)
    }
    
    var unreadCountAtomic = Atomic(0)
    var mentionedUnreadCountAtomic = Atomic(0)
    var onlineUsersAtomic = Atomic<[User]>([])
    
    /// Returns the current unread count.
    public var currentUnreadCount: Int {
        return unreadCountAtomic.get(defaultValue: 0)
    }
    
    /// Returns the current user mentioned unread count.
    public var currentMentionedUnreadCount: Int {
        return mentionedUnreadCountAtomic.get(defaultValue: 0)
    }
    
    /// An option to enable ban users.
    public var banEnabling = BanEnabling.disabled
    var bannedUsers = [User]()
    
    /// Checks if the channel is direct message type between 2 users.
    public var isDirectMessage: Bool {
        return id.hasPrefix("!members") && members.count == 2
    }
    
    /// Init a channel 1-by-1 (direct message) with another member.
    /// - Parameter type: a channel type.
    /// - Parameter member: an another member.
    /// - Parameter extraData: an `Codable` object with extra data of the channel.
    public convenience init(type: ChannelType, with member: Member, extraData: Codable? = nil) {
        var members = [member]
        
        if let currentUser = User.current, member.user != currentUser {
            members.append(currentUser.asMember)
        }
        
        self.init(type: type,
                  id: "",
                  name: member.user.name,
                  imageURL: member.user.avatarURL,
                  members: members,
                  extraData: extraData)
    }
    
    /// Init a channel.
    /// - Parameters:
    ///     - type: a channel type (`ChannelType`).
    ///     - id: a channel id.
    ///     - name: a channel name.
    ///     - imageURL: an image url of the channel.
    ///     - members: a list of members.
    ///     - invitedMembers: invitation list of members.
    ///     - extraData: an `Codable` object with extra data of the channel.
    public init(type: ChannelType,
                id: String,
                name: String? = nil,
                imageURL: URL? = nil,
                lastMessageDate: Date? = nil,
                created: Date = Date(),
                deleted: Date? = nil,
                createdBy: User? = nil,
                frozen: Bool = false,
                members: [Member] = [],
                config: Config = Config(isEmpty: true),
                invitedMembers: [Member] = [],
                extraData: Codable? = nil) {
        self.id = id
        self.cid = ChannelId(type: type, id: id)
        self.type = type
        self.name = (name ?? "").isEmpty ? members.channelName(default: id) : (name ?? "")
        self.imageURL = imageURL
        self.lastMessageDate = lastMessageDate
        self.created = created
        self.deleted = deleted
        self.createdBy = createdBy
        self.frozen = frozen
        self.members = Set(members)
        self.config = config
        self.invitedMembers = Set(invitedMembers)
        self.extraData = ExtraData(extraData)
        
        if type == .unknown, Client.shared.logOptions.isEnabled {
            ClientLogger.log("❌", "Created a bad channel unknown type")
        }
        
        if id.isEmpty, members.count < 2, let currentUser = User.current {
            if let anotherMember = members.first, anotherMember.user != currentUser {
                return
            }
            
            if Client.shared.logOptions.isEnabled {
                ClientLogger.log("❌", "Created a bad channel without id and without members")
            }
        }
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DecodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        self.id = id
        cid = try container.decode(ChannelId.self, forKey: .cid)
        type = try container.decode(ChannelType.self, forKey: .type)
        let config = try container.decode(Config.self, forKey: .config)
        self.config = config
        lastMessageDate = try container.decodeIfPresent(Date.self, forKey: .lastMessageDate)
        created = try container.decodeIfPresent(Date.self, forKey: .created) ?? config.created
        deleted = try container.decodeIfPresent(Date.self, forKey: .deleted)
        createdBy = try container.decodeIfPresent(User.self, forKey: .createdBy)
        frozen = try container.decode(Bool.self, forKey: .frozen)
        imageURL = try? container.decodeIfPresent(URL.self, forKey: .imageURL)
        extraData = ExtraData(ExtraData.decodableTypes.first(where: { $0.isChannel })?.decode(from: decoder))
        let members = try container.decodeIfPresent([Member].self, forKey: .members) ?? []
        self.members = Set<Member>(members)
        let name = try? container.decodeIfPresent(String.self, forKey: .name)
        self.name = (name ?? "").isEmpty ? members.channelName(default: id) : (name ?? "")
        invitedMembers = Set<Member>()
        
        if !isActive {
            Channel.activeChannelIds.append(cid)
        }
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
        
        try container.encode(allMembers, forKey: .members)
    }
}

extension Channel: Hashable {
    
    public static func == (lhs: Channel, rhs: Channel) -> Bool {
        return lhs.cid == rhs.cid
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(cid)
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
        /// Indicates if the config was created with an empty channel data.
        public let isEmpty: Bool
        
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
            isEmpty = false
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
                    created: Date = .default,
                    updated: Date = .default,
                    isEmpty: Bool = false) {
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
            self.isEmpty = isEmpty
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
            return lhs.name == rhs.name
        }
        
        public func hash(into hasher: inout Hasher) {
            return hasher.combine(name)
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

extension Channel {
    static let unused = Channel(type: .messaging, id: "5h0u1d-n3v3r-b3-u5'd")
}
