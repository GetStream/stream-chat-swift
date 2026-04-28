//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ThreadUpdatedEventOpenAPI: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    var channelId: String?
    var channelType: String?
    var cid: String?
    var createdAt: Date
    var custom: [String: RawJSON]
    var receivedAt: Date?
    var thread: ThreadResponse?
    var type: String = "thread.updated"

    init(channelId: String? = nil, channelType: String? = nil, cid: String? = nil, createdAt: Date, custom: [String: RawJSON], receivedAt: Date? = nil, thread: ThreadResponse? = nil) {
        self.channelId = channelId
        self.channelType = channelType
        self.cid = cid
        self.createdAt = createdAt
        self.custom = custom
        self.receivedAt = receivedAt
        self.thread = thread
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

    static func == (lhs: ThreadUpdatedEventOpenAPI, rhs: ThreadUpdatedEventOpenAPI) -> Bool {
        lhs.channelId == rhs.channelId &&
            lhs.channelType == rhs.channelType &&
            lhs.cid == rhs.cid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.thread == rhs.thread &&
            lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channelId)
        hasher.combine(channelType)
        hasher.combine(cid)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(receivedAt)
        hasher.combine(thread)
        hasher.combine(type)
    }
}
