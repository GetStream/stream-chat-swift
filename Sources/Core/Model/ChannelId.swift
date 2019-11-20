//
//  ChannelId.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 20/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A channel type and id.
public struct ChannelId: Codable, Hashable, CustomStringConvertible {
    private static let any = "*"
    private static let separator: Character = ":"
    
    enum Error: Swift.Error {
        case decoding(String)
    }
    
    /// A channel type of the event.
    public let type: ChannelType
    /// A channel id of the event.
    public let id: String
    
    /// Init a ChannelId.
    /// - Parameter type: a channel type.
    /// - Parameter id: a channel id.
    public init(type: ChannelType, id: String) {
        self.type = type
        self.id = id
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let cid = try container.decode(String.self)
        
        if cid == ChannelId.any {
            type = .unknown
            id = ChannelId.any
            return
        }
        
        if cid.contains(ChannelId.separator) {
            let channelPair = cid.split(separator: ChannelId.separator)
            type = ChannelType(rawValue: String(channelPair[0]))
            id = String(channelPair[1])
        } else {
            throw ChannelId.Error.decoding(cid)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if id == ChannelId.any {
            try container.encode(ChannelId.any)
        } else {
            try container.encode("\(type.rawValue):\(id)")
        }
    }
    
    public var description: String {
        return "\(type)\(ChannelId.separator)\(id)"
    }
}
