//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class DraftResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var channel: ChannelResponse?
    var channelCid: String
    var createdAt: Date
    var message: DraftPayloadResponse
    var parentId: String?
    var parentMessage: MessageResponse?
    var quotedMessage: MessageResponse?

    init(channel: ChannelResponse? = nil, channelCid: String, createdAt: Date, message: DraftPayloadResponse, parentId: String? = nil, parentMessage: MessageResponse? = nil, quotedMessage: MessageResponse? = nil) {
        self.channel = channel
        self.channelCid = channelCid
        self.createdAt = createdAt
        self.message = message
        self.parentId = parentId
        self.parentMessage = parentMessage
        self.quotedMessage = quotedMessage
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case channelCid = "channel_cid"
        case createdAt = "created_at"
        case message
        case parentId = "parent_id"
        case parentMessage = "parent_message"
        case quotedMessage = "quoted_message"
    }

    static func == (lhs: DraftResponse, rhs: DraftResponse) -> Bool {
        lhs.channel == rhs.channel &&
            lhs.channelCid == rhs.channelCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.message == rhs.message &&
            lhs.parentId == rhs.parentId &&
            lhs.parentMessage == rhs.parentMessage &&
            lhs.quotedMessage == rhs.quotedMessage
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channel)
        hasher.combine(channelCid)
        hasher.combine(createdAt)
        hasher.combine(message)
        hasher.combine(parentId)
        hasher.combine(parentMessage)
        hasher.combine(quotedMessage)
    }
}
