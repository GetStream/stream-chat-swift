//
//  Channel.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A Channel class.
public final class Channel: Codable, Equatable {
    /// Coding keys for the decoding.
    public enum DecodingKeys: String, CodingKey {
        case id
        case cid
        case type
        case lastMessageDate = "last_message_at"
        case createdBy = "created_by"
        case created = "created_at"
        case config
        case frozen
        case name
        case imageURL = "image"
        case extraData
        case members
    }
    
    /// Coding keys for the encoding.
    private enum EncodingKeys: String, CodingKey {
        case name
        case imageURL = "image"
        case members
        case messages
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
    /// A creator of the channel.
    public let createdBy: User?
    /// A config.
    public let config: Config
    let frozen: Bool
    /// A list of user ids of the channel members.
    public internal(set) var memberIds: [String] = []
    /// An extra data for the channel.
    public let extraData: ExtraData?
    
    /// Init a channel.
    ///
    /// - Parameters:
    ///     - type: a channel type (`ChannelType`).
    ///     - id: a channel id.
    ///     - name: a channel name.
    ///     - imageURL: an image url of the channel.
    ///     - memberIds: a list of user ids of the channel members.
    ///     - extraData: an `Codable` object with extra data of the channel.
    public init(type: ChannelType = .messaging,
                id: String,
                name: String? = nil,
                imageURL: URL? = nil,
                memberIds: [String] = [],
                extraData: Codable? = nil) {
        self.id = id
        self.cid = "\(type.rawValue):\(id)"
        self.type = type
        self.name = name ?? id
        self.imageURL = imageURL
        lastMessageDate = nil
        createdBy = nil
        self.memberIds = memberIds
        frozen = false
        
        if let extraData = extraData {
            self.extraData = ExtraData(extraData)
        } else {
            self.extraData = nil
        }
        
        config = Config(name: "",
                        automodBehavior: "",
                        automodEnabled: "",
                        reactionsEnabled: false,
                        typingEventsEnabled: false,
                        readEventsEnabled: false,
                        connectEventsEnabled: false,
                        repliesEnabled: false,
                        searchEnabled: false,
                        mutesEnabled: false,
                        messageRetention: "",
                        maxMessageLength: 0,
                        commands: [],
                        created: Date(),
                        updated: Date())
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DecodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        self.id = id
        cid = try container.decode(String.self, forKey: .cid)
        type = try container.decode(ChannelType.self, forKey: .type)
        config = try container.decode(Config.self, forKey: .config)
        lastMessageDate = try container.decodeIfPresent(Date.self, forKey: .lastMessageDate)
        createdBy = try container.decodeIfPresent(User.self, forKey: .createdBy)
        frozen = try container.decode(Bool.self, forKey: .frozen)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? id
        imageURL = try? container.decodeIfPresent(URL.self, forKey: .imageURL)
        extraData = .decode(from: decoder, ExtraData.decodableTypes.first(where: { $0.isChannel }))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: EncodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encode(memberIds, forKey: .members)
        extraData?.encodeSafely(to: encoder)
    }
    
    public static func == (lhs: Channel, rhs: Channel) -> Bool {
        return lhs.cid == rhs.cid
    }
}

// MARK: - Config

public extension Channel {
    /// A channel config.
    struct Config: Decodable {
        private enum CodingKeys: String, CodingKey {
            case name
            case automodBehavior = "automod_behavior"
            case automodEnabled = "automod"
            case reactionsEnabled = "reactions"
            case typingEventsEnabled = "typing_events"
            case readEventsEnabled = "read_events"
            case connectEventsEnabled = "connect_events"
            case repliesEnabled = "replies"
            case searchEnabled = "search"
            case mutesEnabled = "mutes"
            case messageRetention = "message_retention"
            case maxMessageLength = "max_message_length"
            case commands
            case created = "created_at"
            case updated = "updated_at"
        }
        
        
        let name: String
        let automodBehavior: String
        let automodEnabled: String
        /// If users are allowed to add reactions to messages. Enabled by default.
        public let reactionsEnabled: Bool
        /// Controls if typing indicators are shown. Enabled by default.
        public let typingEventsEnabled: Bool
        /// Controls whether the chat shows how far you’ve read. Enabled by default.
        public let readEventsEnabled: Bool
        /// Determines if events are fired for connecting and disconnecting to a chat. Enabled by default.
        let connectEventsEnabled: Bool
        /// Enables message threads and replies. Enabled by default.
        public let repliesEnabled: Bool
        /// Controls if messages should be searchable (this is a premium feature). Disabled by default.
        public let searchEnabled: Bool
        /// Determines if users are able to mute other users. Enabled by default.
        public let mutesEnabled: Bool
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
        
        public func hash(into hasher: inout Hasher) {
            return hasher.combine(name)
        }
    }
}

// MARK: - Channel Type

/// A channel type.
public enum ChannelType: String, Codable {
    case unknown
    case livestream
    case messaging
    case team
    case gaming
    case commerce
    
    /// A channel type title.
    public var title: String {
        return rawValue.capitalized
    }
}
