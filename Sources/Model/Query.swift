//
//  Query.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 02/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

public struct Query: Codable {
    private enum CodingKeys: String, CodingKey {
        case data
        case channel
        case members
        case messages
        case state
    }
    
    public let channel: Channel
    public let members: [User]
    public let messages: [Message]
    public let state: Bool = true
    
    public init(channel: Channel, members: [User]) {
        self.channel = channel
        self.members = members
        messages = []
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        channel = try container.decode(Channel.self, forKey: .channel)
        members = try container.decode([User].self, forKey: .members)
        messages = try container.decode([Message].self, forKey: .messages)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(state, forKey: .state)
        channel.members = members
        try container.encode(channel, forKey: .data)
        channel.members = []
    }
}
