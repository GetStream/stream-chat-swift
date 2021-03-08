//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type describes the outgoing JSON to `message/{id}/action` endpoint
struct AttachmentActionRequestBody: Encodable {
    private enum CodingKeys: String, CodingKey {
        case channelId = "id"
        case channelType = "type"
        case messageId = "message_id"
        case data = "form_data"
    }

    let cid: ChannelId
    let messageId: MessageId
    let action: AttachmentAction

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(cid.id, forKey: .channelId)
        try container.encode(cid.type, forKey: .channelType)
        try container.encode(messageId, forKey: .messageId)
        try container.encode([action.name: action.value], forKey: .data)
    }
}
