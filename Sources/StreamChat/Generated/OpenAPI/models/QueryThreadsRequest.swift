//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryThreadsRequest: Sendable, Encodable, JSONEncodable {
    /// Filter to apply to the query
    let filter: (any Encodable & Sendable)?
    let limit: Int?
    let memberLimit: Int?
    let next: String?
    /// Limit the number of participants returned per each thread
    let participantLimit: Int?
    let prev: String?
    /// Limit the number of replies returned per each thread
    let replyLimit: Int?
    /// Array of sort parameters
    let sort: [SortParamRequest]?
    /// Start watching the channel this thread belongs to
    let watch: Bool?

    init(
        filter: (any Encodable & Sendable)? = nil,
        limit: Int? = nil,
        memberLimit: Int? = nil,
        next: String? = nil,
        participantLimit: Int? = nil,
        prev: String? = nil,
        replyLimit: Int? = nil,
        sort: [SortParamRequest]? = nil,
        watch: Bool? = nil
    ) {
        self.filter = filter
        self.limit = limit
        self.memberLimit = memberLimit
        self.next = next
        self.participantLimit = participantLimit
        self.prev = prev
        self.replyLimit = replyLimit
        self.sort = sort
        self.watch = watch
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case filter
        case limit
        case memberLimit = "member_limit"
        case next
        case participantLimit = "participant_limit"
        case prev
        case replyLimit = "reply_limit"
        case sort
        case watch
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let filter {
            try container.encode(filter, forKey: .filter)
        }
        try container.encodeIfPresent(limit, forKey: .limit)
        try container.encodeIfPresent(memberLimit, forKey: .memberLimit)
        try container.encodeIfPresent(next, forKey: .next)
        try container.encodeIfPresent(participantLimit, forKey: .participantLimit)
        try container.encodeIfPresent(prev, forKey: .prev)
        try container.encodeIfPresent(replyLimit, forKey: .replyLimit)
        try container.encodeIfPresent(sort, forKey: .sort)
        try container.encodeIfPresent(watch, forKey: .watch)
    }
}
