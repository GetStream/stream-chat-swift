//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryThreadsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Filter to apply to the query
    var filter: [String: RawJSON]?
    var limit: Int?
    var memberLimit: Int?
    var next: String?
    /// Limit the number of participants returned per each thread
    var participantLimit: Int?
    var prev: String?
    /// Limit the number of replies returned per each thread
    var replyLimit: Int?
    /// [RawJSON] of sort parameters
    var sort: [SortParamRequestModel]?
    /// Start watching the channel this thread belongs to
    var watch: Bool?

    init(filter: [String: RawJSON]? = nil, limit: Int? = nil, memberLimit: Int? = nil, next: String? = nil, participantLimit: Int? = nil, prev: String? = nil, replyLimit: Int? = nil, sort: [SortParamRequestModel]? = nil, watch: Bool? = nil) {
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

    static func == (lhs: QueryThreadsRequest, rhs: QueryThreadsRequest) -> Bool {
        lhs.filter == rhs.filter &&
            lhs.limit == rhs.limit &&
            lhs.memberLimit == rhs.memberLimit &&
            lhs.next == rhs.next &&
            lhs.participantLimit == rhs.participantLimit &&
            lhs.prev == rhs.prev &&
            lhs.replyLimit == rhs.replyLimit &&
            lhs.sort == rhs.sort &&
            lhs.watch == rhs.watch
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(filter)
        hasher.combine(limit)
        hasher.combine(memberLimit)
        hasher.combine(next)
        hasher.combine(participantLimit)
        hasher.combine(prev)
        hasher.combine(replyLimit)
        hasher.combine(sort)
        hasher.combine(watch)
    }
}
