//
//  MessageAction.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 13/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

struct MessageAction: Encodable {
    private enum CodingKeys: String, CodingKey {
        case channelId = "id"
        case channelType = "type"
        case messageId = "message_id"
        case data = "form_data"
    }
    
    let channel: Channel
    let message: Message
    let action: Attachment.Action
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(channel.id, forKey: .channelId)
        try container.encode(channel.type, forKey: .channelType)
        try container.encode(message.id, forKey: .messageId)
        try container.encode([action.name: action.value], forKey: .data)
    }
}
