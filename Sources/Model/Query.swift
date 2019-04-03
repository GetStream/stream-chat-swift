//
//  Query.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 02/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

public struct Query: Codable {
    enum CodingKeys: String, CodingKey {
        case data
        case channel
        case members
    }
    
    public let channel: Channel
    public let members: [User]
    
    public init(channel: Channel, members: [User]) {
        self.channel = channel
        self.members = members
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        channel = try container.decode(Channel.self, forKey: .channel)
        members = try container.decode([User].self, forKey: .members)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        channel.members = members
        try container.encode(channel, forKey: .data)
        channel.members = []
    }
}
