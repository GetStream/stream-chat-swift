//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryFutureChannelBansPayload: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Whether to exclude expired bans or not
    var excludeExpiredBans: Bool?
    /// Number of records to return
    var limit: Int?
    /// Number of records to offset
    var offset: Int?
    /// Filter by the target user ID. For server-side requests only.
    var targetUserId: String?

    init(excludeExpiredBans: Bool? = nil, limit: Int? = nil, offset: Int? = nil, targetUserId: String? = nil) {
        self.excludeExpiredBans = excludeExpiredBans
        self.limit = limit
        self.offset = offset
        self.targetUserId = targetUserId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case excludeExpiredBans = "exclude_expired_bans"
        case limit
        case offset
        case targetUserId = "target_user_id"
    }

    static func == (lhs: QueryFutureChannelBansPayload, rhs: QueryFutureChannelBansPayload) -> Bool {
        lhs.excludeExpiredBans == rhs.excludeExpiredBans &&
            lhs.limit == rhs.limit &&
            lhs.offset == rhs.offset &&
            lhs.targetUserId == rhs.targetUserId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(excludeExpiredBans)
        hasher.combine(limit)
        hasher.combine(offset)
        hasher.combine(targetUserId)
    }
}
