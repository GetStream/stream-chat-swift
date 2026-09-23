//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ThreadUpdatedEventDTO: Sendable, Event, Decodable {
    let channelId: String?
    let channelType: String?
    let cid: ChannelId?
    let createdAt: Date
    let custom: [String: RawJSON]
    let receivedAt: Date?
    let thread: ThreadResponse?
    let type: String

    init(
        channelId: String? = nil,
        channelType: String? = nil,
        cid: ChannelId? = nil,
        createdAt: Date,
        custom: [String: RawJSON],
        receivedAt: Date? = nil,
        thread: ThreadResponse? = nil,
        type: String = "thread.updated"
    ) {
        self.channelId = channelId
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.custom = custom
        self.receivedAt = receivedAt
        self.thread = thread
        self.type = type
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelId = "channel_id"
        case channelType = "channel_type"
        case cid
        case createdAt = "created_at"
        case custom
        case receivedAt = "received_at"
        case thread
        case type
    }
}
