//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollVoteChangedEventOpenAPI: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    var activityId: String?
    /// The CID of the channel containing the poll
    var cid: String?
    /// Date/time of creation
    var createdAt: Date
    var custom: [String: RawJSON]
    /// The ID of the message containing the poll
    var messageId: String?
    var poll: PollResponseData
    var pollVote: PollVoteResponseData
    var receivedAt: Date?
    /// The type of event: "poll.vote_changed" in this case
    var type: String = "poll.vote_changed"

    init(activityId: String? = nil, cid: String? = nil, createdAt: Date, custom: [String: RawJSON], messageId: String? = nil, poll: PollResponseData, pollVote: PollVoteResponseData, receivedAt: Date? = nil) {
        self.activityId = activityId
        self.cid = cid
        self.createdAt = createdAt
        self.custom = custom
        self.messageId = messageId
        self.poll = poll
        self.pollVote = pollVote
        self.receivedAt = receivedAt
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

    static func == (lhs: PollVoteChangedEventOpenAPI, rhs: PollVoteChangedEventOpenAPI) -> Bool {
        lhs.activityId == rhs.activityId &&
            lhs.cid == rhs.cid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.custom == rhs.custom &&
            lhs.messageId == rhs.messageId &&
            lhs.poll == rhs.poll &&
            lhs.pollVote == rhs.pollVote &&
            lhs.receivedAt == rhs.receivedAt &&
            lhs.type == rhs.type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(activityId)
        hasher.combine(cid)
        hasher.combine(createdAt)
        hasher.combine(custom)
        hasher.combine(messageId)
        hasher.combine(poll)
        hasher.combine(pollVote)
        hasher.combine(receivedAt)
        hasher.combine(type)
    }
}
