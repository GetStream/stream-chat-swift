//
//  MessageAction.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 13/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A message action from commands.
public struct MessageAction: Encodable {
    private enum CodingKeys: String, CodingKey {
        case channelId = "id"
        case channelType = "type"
        case messageId = "message_id"
        case data = "form_data"
    }
    
    /// A channel of a message.
    public let channel: Channel
    /// A message.
    public let message: Message
    /// A message action.
    public let action: Attachment.Action
    
    /// Init a message action.
    ///
    /// - Parameters:
    ///   - channel: a channel of a message.
    ///   - message: a message.
    ///   - action: an action.
    public init(channel: Channel, message: Message, action: Attachment.Action) {
        self.channel = channel
        self.message = message
        self.action = action
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(channel.id, forKey: .channelId)
        try container.encode(channel.type, forKey: .channelType)
        try container.encode(message.id, forKey: .messageId)
        try container.encode([action.name: action.value], forKey: .data)
    }
}
