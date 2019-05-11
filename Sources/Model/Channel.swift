//
//  Channel.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

public final class Channel: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case cid
        case type
        case lastMessageDate = "last_message_at"
        case createdBy = "created_by"
        case config
        case frozen
        case name
        case imageURL = "image"
    }
    
    public enum DataCodingKeys: String, CodingKey {
        case name
        case imageURL = "image"
        case members
        case messages
    }
    
    private(set) var id: String = UUID().uuidString
    private(set) var cid: String
    private(set) var type: ChannelType = .messaging
    private(set) var lastMessageDate: Date? = nil
    private(set) var createdBy: User? = nil
    private(set) var config: Config? = nil
    private(set) var frozen: Bool = false
    
    public let name: String
    public var imageURL: URL?
    var userIds: [String] = []
    
    public init(type: ChannelType = .messaging, id: String, name: String, imageURL: URL?) {
        self.id = id
        self.type = type
        self.cid = "\(type.rawValue):\(id)"
        self.name = name
        self.imageURL = imageURL
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        cid = try container.decode(String.self, forKey: .cid)
        type = try container.decode(ChannelType.self, forKey: .type)
        config = try container.decode(Config.self, forKey: .config)
        lastMessageDate = try container.decodeIfPresent(Date.self, forKey: .lastMessageDate)
        createdBy = try container.decodeIfPresent(User.self, forKey: .createdBy)
        frozen = try container.decode(Bool.self, forKey: .frozen)
        name = try container.decode(String.self, forKey: .name)
        imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DataCodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(imageURL, forKey: .imageURL)
        try container.encode(userIds, forKey: .members)
    }
}

// MARK: - Config

extension Channel {
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
        let reactionsEnabled: Bool
        let typingEventsEnabled: Bool
        let readEventsEnabled: Bool
        let connectEventsEnabled: Bool
        let repliesEnabled: Bool
        let searchEnabled: Bool
        let mutesEnabled: Bool
        let messageRetention: String
        let maxMessageLength: Int
        let commands: [Command]
        let created: Date
        let updated: Date
    }
    
    struct Command: Decodable, Hashable {
        let name: String
        let description: String
        let set: String
        let args: String
        
        func hash(into hasher: inout Hasher) {
            return hasher.combine(name)
        }
    }
}

// MARK: - Channel Type

public enum ChannelType: String, Codable {
    case unknown
    case livestream
    case messaging
    case team
    case gaming
    case commerce
}
