//
//  Channel.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

open class Channel: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case lastMessageDate = "last_message_at"
        case createdByUser = "created_by"
        case frozen
        case name
        case imageURL = "image"
    }
    
    public enum DataCodingKeys: String, CodingKey {
        case name
        case imageURL = "image"
        case members
    }
    
    private(set) var id: String = UUID().uuidString
    private(set) var type: ChannelType = .messaging
    private(set) var lastMessageDate: Date? = nil
    private(set) var createdByUser: User? = nil
    private(set) var frozen: Bool = false
    
    public let name: String
    public var imageURL: URL?
    var members: [User] = []
    
    public init(type: ChannelType = .messaging, id: String, name: String, imageURL: URL?) {
        self.id = id
        self.type = type
        self.name = name
        self.imageURL = imageURL
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(ChannelType.self, forKey: .type)
        lastMessageDate = try container.decode(Date.self, forKey: .lastMessageDate)
        createdByUser = try container.decode(User.self, forKey: .createdByUser)
        frozen = try container.decode(Bool.self, forKey: .frozen)
        name = try container.decode(String.self, forKey: .name)
        imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DataCodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(imageURL, forKey: .imageURL)
        try container.encode(members, forKey: .members)
    }
}

// MARK: - Requests

extension Channel {
    
    public func create(members: [User], _ completion: @escaping Client.Completion<Query>) {
        Client.shared.request(endpoint: ChatEndpoint.query(Query(channel: self, members: members)), completion)
    }
    
    public func send(_ message: Message, _ completion: @escaping Client.Completion<Channel>) {
    }
}

// MARK: - Channel Type

public enum ChannelType: String, Codable {
    case livestream
    case messaging
    case team
    case gaming
    case commerce
}
