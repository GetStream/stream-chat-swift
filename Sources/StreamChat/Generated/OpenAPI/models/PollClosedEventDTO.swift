//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollClosedEventDTO: Sendable, Event, Decodable {
    let activityId: String?
    /// The CID of the channel containing the poll
    let cid: ChannelId?
    /// Date/time of creation
    let createdAt: Date
    let custom: [String: RawJSON]
    /// The ID of the message containing the poll
    let messageId: String?
    let poll: PollPayload
    let receivedAt: Date?
    /// The type of event: "poll.closed" in this case
    let type: String

    init(
        activityId: String? = nil,
        cid: ChannelId? = nil,
        createdAt: Date,
        custom: [String: RawJSON],
        messageId: String? = nil,
        poll: PollPayload,
        receivedAt: Date? = nil,
        type: String = "poll.closed"
    ) {
        self.activityId = activityId
        self.cid = cid
        self.createdAt = createdAt
        self.custom = custom
        self.messageId = messageId
        self.poll = poll
        self.receivedAt = receivedAt
        self.type = type
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case activityId = "activity_id"
        case cid
        case createdAt = "created_at"
        case custom
        case messageId = "message_id"
        case poll
        case receivedAt = "received_at"
        case type
    }
}
