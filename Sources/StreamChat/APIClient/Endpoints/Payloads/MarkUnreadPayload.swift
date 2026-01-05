//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

enum MarkUnreadCriteria: Sendable, Equatable {
    /// The ID of the message from where the channel is marked unread
    case messageId(String)
    /// The timestamp of the message from where the channel is marked unread
    case messageTimestamp(Date)
}

struct MarkUnreadPayload: Encodable, Sendable {
    let criteria: MarkUnreadCriteria
    let userId: String
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        switch criteria {
        case .messageId(let messageId):
            try container.encode(messageId, forKey: .messageId)
        case .messageTimestamp(let messageTimestamp):
            try container.encode(messageTimestamp, forKey: .messageTimestamp)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case messageTimestamp = "message_timestamp"
        case userId = "user_id"
    }
}
