//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChatDraftResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var channelCid: String
    var createdAt: Date
    var message: ChatDraftPayloadResponse
    var parentId: String?
    var parentMessage: ChatMessageResponse?
    var quotedMessage: ChatMessageResponse?

    init(channelCid: String, createdAt: Date, message: ChatDraftPayloadResponse, parentId: String? = nil, parentMessage: ChatMessageResponse? = nil, quotedMessage: ChatMessageResponse? = nil) {
        self.channelCid = channelCid
        self.createdAt = createdAt
        self.message = message
        self.parentId = parentId
        self.parentMessage = parentMessage
        self.quotedMessage = quotedMessage
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelCid = "channel_cid"
        case createdAt = "created_at"
        case message
        case parentId = "parent_id"
        case parentMessage = "parent_message"
        case quotedMessage = "quoted_message"
    }

    static func == (lhs: ChatDraftResponse, rhs: ChatDraftResponse) -> Bool {
        lhs.channelCid == rhs.channelCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.message == rhs.message &&
            lhs.parentId == rhs.parentId &&
            lhs.parentMessage == rhs.parentMessage &&
            lhs.quotedMessage == rhs.quotedMessage
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channelCid)
        hasher.combine(createdAt)
        hasher.combine(message)
        hasher.combine(parentId)
        hasher.combine(parentMessage)
        hasher.combine(quotedMessage)
    }
}
