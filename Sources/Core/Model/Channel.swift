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
    private enum EncodingKeys: String, CodingKey {
        case name
        case imageURL = "image"
        case members
        case invites
    }
    
    /// A channel id.
    public let id: String
    /// A channel type + id.
    public let cid: String
    /// A channel type.
    public let type: ChannelType
    /// A channel name.
    public let name: String
    /// An image of the channel.
    public var imageURL: URL?
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
    let frozen: Bool
    /// A list of user ids of the channel members.
    public internal(set) var members = Set<Member>([])
    /// A list of users to invite in the channel.
    var invitedUsers = Set<User>([])
    /// An extra data for the channel.
    public let extraData: ExtraData?
    
    /// Check if the channel was deleted.
    public var isDeleted: Bool {
        return deleted != nil
    }
    
    static private var activeChannelIds: [String] = []
    
    var isActive: Bool {
        return Channel.activeChannelIds.contains(cid)
    }
    
    var unreadCountAtomic = Atomic(0)
    var onlineUsersAtomic = Atomic<[User]>([])
    
    /// Init a channel 1-by-1 with another member.
    /// - Parameter type: a channel type.
    /// - Parameter member: an another member.
    /// - Parameter extraData: an `Codable` object with extra data of the channel.
    public convenience init(type: ChannelType, with member: Member, extraData: Codable? = nil) {
        var members = [member]
        
        if let currentUser = User.current, member.user != currentUser {
            members.append(currentUser.asMember)
        }
        
        self.init(type: type, id: "", name: member.user.name, members: members, extraData: extraData)
    }
    
    /// Init a channel.
    /// - Parameters:
    ///     - type: a channel type (`ChannelType`).
    ///     - id: a channel id.
    ///     - name: a channel name.
    ///     - imageURL: an image url of the channel.
    ///     - members: a list of members.
    ///     - extraData: an `Codable` object with extra data of the channel.
    public init(type: ChannelType,
                id: String,
                name: String? = nil,
                imageURL: URL? = nil,
                members: [Member] = [],
                extraData: Codable? = nil) {
        self.id = id
        self.cid = "\(type.rawValue):\(id)"
        self.type = type
        self.name = name ?? id
        self.imageURL = imageURL
        lastMessageDate = nil
        created = Date()
        deleted = nil
        createdBy = nil
        self.members = Set(members)
        frozen = false
        config = Config()
        
        if let extraData = extraData {
            self.extraData = ExtraData(extraData)
        } else {
            self.extraData = nil
        }
        
        if type == .unknown {
            ClientLogger.log("❌", "Created a bad channel unknown type")
        }

        if id.isEmpty, members.count < 2, let currentUser = User.current {
            if let anotherMember = members.first, anotherMember.user != currentUser {
                return
            }
            
            ClientLogger.log("❌", "Created a bad channel without id and without members")
        }
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DecodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        self.id = id
        cid = try container.decode(String.self, forKey: .cid)
        type = try container.decode(ChannelType.self, forKey: .type)
        let config = try container.decode(Config.self, forKey: .config)
        self.config = config
        lastMessageDate = try container.decodeIfPresent(Date.self, forKey: .lastMessageDate)
        created = try container.decodeIfPresent(Date.self, forKey: .created) ?? config.created
        deleted = try container.decodeIfPresent(Date.self, forKey: .deleted)
        createdBy = try container.decodeIfPresent(User.self, forKey: .createdBy)
        frozen = try container.decode(Bool.self, forKey: .frozen)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? id
        imageURL = try? container.decodeIfPresent(URL.self, forKey: .imageURL)
        extraData = .decode(from: decoder, ExtraData.decodableTypes.first(where: { $0.isChannel }))
        members = Set<Member>((try? container.decodeIfPresent([Member].self, forKey: .members)) ?? [])
        
        if !isActive {
            Channel.activeChannelIds.append(cid)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: EncodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encode(members, forKey: .members)
        extraData?.encodeSafely(to: encoder)
        
        if !invitedUsers.isEmpty {
            try container.encode(invitedUsers.map({ $0.id }), forKey: .invites)
        }
    }
    
    func addInvitedUser(_ user: User) {
        members.insert(user.asMember)
        invitedUsers.insert(user)
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
        private enum CodingKeys: String, CodingKey {
            case reactionsEnabled = "reactions"
            case typingEventsEnabled = "typing_events"
            case readEventsEnabled = "read_events"
            case connectEventsEnabled = "connect_events"
            case uploadsEnabled = "uploads"
            case repliesEnabled = "replies"
            case searchEnabled = "search"
            case mutesEnabled = "mutes"
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
        let connectEventsEnabled: Bool
        /// Enables uploads.
        public let uploadsEnabled: Bool
        /// Enables message threads and replies. Enabled by default.
        public let repliesEnabled: Bool
        /// Controls if messages should be searchable (this is a premium feature). Disabled by default.
        public let searchEnabled: Bool
        /// Determines if users are able to mute other users. Enabled by default.
        public let mutesEnabled: Bool
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
            messageRetention = try container.decode(String.self, forKey: .messageRetention)
            maxMessageLength = try container.decode(Int.self, forKey: .maxMessageLength)
            commands = try container.decodeIfPresent([Command].self, forKey: .commands) ?? []
            flagsEnabled = commands.first(where: { $0.name.contains("flag") }) != nil
            created = try container.decode(Date.self, forKey: .created)
            updated = try container.decode(Date.self, forKey: .updated)
        }
        
        init() {
            reactionsEnabled = false
            typingEventsEnabled = false
            readEventsEnabled = false
            connectEventsEnabled = false
            uploadsEnabled = false
            repliesEnabled = false
            searchEnabled = false
            mutesEnabled = false
            flagsEnabled = false
            messageRetention = ""
            maxMessageLength = 0
            commands = []
            created = Date()
            updated = Date()
        }
    }
    
    /// A command in a message, e.g. /giphy.
    struct Command: Decodable, Hashable {
        /// A command name.
        public let name: String
        /// A description.
        public let description: String
        let set: String
        /// Args for the command.
        public let args: String
        
        public static func == (lhs: Command, rhs: Command) -> Bool {
            return lhs.name == rhs.name
        }
        
        public func hash(into hasher: inout Hasher) {
            return hasher.combine(name)
        }
    }
}

// MARK: - Channel Type

/// A channel type.
public enum ChannelType: String, Codable {
    /// A channel type.
    case unknown, livestream, messaging, team, gaming, commerce
    
    /// A channel type title.
    public var title: String {
        return rawValue.capitalized
    }
}

extension Channel {
    static let unused = Channel(type: .messaging, id: "5h0u1d-n3v3r-b3-u5'd")
}
