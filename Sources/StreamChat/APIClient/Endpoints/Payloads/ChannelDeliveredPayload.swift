//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A payload representing a delivered message with its channel and message identifiers.
struct DeliveredMessagePayload: Encodable, Equatable {
    let cid: ChannelId
    let id: MessageId
    
    init(cid: ChannelId, id: MessageId) {
        self.cid = cid
        self.id = id
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(cid, forKey: .cid)
        try container.encode(id, forKey: .id)
    }
    
    private enum CodingKeys: String, CodingKey {
        case cid
        case id
    }
}

/// A request payload for marking channels as delivered.
struct ChannelDeliveredRequestPayload: Encodable, Equatable {
    let latestDeliveredMessages: [DeliveredMessagePayload]
    
    init(latestDeliveredMessages: [DeliveredMessagePayload]) {
        self.latestDeliveredMessages = latestDeliveredMessages
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latestDeliveredMessages, forKey: .latestDeliveredMessages)
    }
    
    private enum CodingKeys: String, CodingKey {
        case latestDeliveredMessages = "latest_delivered_messages"
    }
}
