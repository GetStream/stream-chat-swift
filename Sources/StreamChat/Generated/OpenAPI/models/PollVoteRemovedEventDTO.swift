//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollVoteRemovedEventDTO: Sendable, Event, Decodable {
    let activityId: String?
    /// The CID of the channel containing the poll
    let cid: ChannelId?
    /// Date/time of creation
    let createdAt: Date
    let custom: [String: RawJSON]
    /// The ID of the message containing the poll
    let messageId: String?
    let poll: PollPayload
    let pollVote: PollVotePayload
    let receivedAt: Date?
    /// The type of event: "poll.vote_removed" in this case
    let type: String

    init(
        activityId: String? = nil,
        cid: ChannelId? = nil,
        createdAt: Date,
        custom: [String: RawJSON],
        messageId: String? = nil,
        poll: PollPayload,
        pollVote: PollVotePayload,
        receivedAt: Date? = nil,
        type: String = "poll.vote_removed"
    ) {
        self.activityId = activityId
        self.cid = cid
        self.createdAt = createdAt
        self.custom = custom
        self.messageId = messageId
        self.poll = poll
        self.pollVote = pollVote
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
        case pollVote = "poll_vote"
        case receivedAt = "received_at"
        case type
    }
}
