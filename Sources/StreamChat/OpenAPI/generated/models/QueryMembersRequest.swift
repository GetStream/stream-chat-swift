//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct QueryMembersRequest: Codable, Hashable {
    public var type: String
    public var filterConditions: [String: RawJSON]
    public var createdAtAfter: Date? = nil
    public var createdAtAfterOrEqual: Date? = nil
    public var createdAtBefore: Date? = nil
    public var createdAtBeforeOrEqual: Date? = nil
    public var id: String? = nil
    public var limit: Int? = nil
    public var offset: Int? = nil
    public var userId: String? = nil
    public var userIdGt: String? = nil
    public var userIdGte: String? = nil
    public var userIdLt: String? = nil
    public var userIdLte: String? = nil
    public var members: [ChannelMember?]? = nil
    public var sort: [SortParam?]? = nil
    public var user: UserObject? = nil

    public init(type: String, filterConditions: [String: RawJSON], createdAtAfter: Date? = nil, createdAtAfterOrEqual: Date? = nil, createdAtBefore: Date? = nil, createdAtBeforeOrEqual: Date? = nil, id: String? = nil, limit: Int? = nil, offset: Int? = nil, userId: String? = nil, userIdGt: String? = nil, userIdGte: String? = nil, userIdLt: String? = nil, userIdLte: String? = nil, members: [ChannelMember?]? = nil, sort: [SortParam?]? = nil, user: UserObject? = nil) {
        self.type = type
        self.filterConditions = filterConditions
        self.createdAtAfter = createdAtAfter
        self.createdAtAfterOrEqual = createdAtAfterOrEqual
        self.createdAtBefore = createdAtBefore
        self.createdAtBeforeOrEqual = createdAtBeforeOrEqual
        self.id = id
        self.limit = limit
        self.offset = offset
        self.userId = userId
        self.userIdGt = userIdGt
        self.userIdGte = userIdGte
        self.userIdLt = userIdLt
        self.userIdLte = userIdLte
        self.members = members
        self.sort = sort
        self.user = user
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        case filterConditions = "filter_conditions"
        case createdAtAfter = "created_at_after"
        case createdAtAfterOrEqual = "created_at_after_or_equal"
        case createdAtBefore = "created_at_before"
        case createdAtBeforeOrEqual = "created_at_before_or_equal"
        case id
        case limit
        case offset
        case userId = "user_id"
        case userIdGt = "user_id_gt"
        case userIdGte = "user_id_gte"
        case userIdLt = "user_id_lt"
        case userIdLte = "user_id_lte"
        case members
        case sort
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(filterConditions, forKey: .filterConditions)
        try container.encode(createdAtAfter, forKey: .createdAtAfter)
        try container.encode(createdAtAfterOrEqual, forKey: .createdAtAfterOrEqual)
        try container.encode(createdAtBefore, forKey: .createdAtBefore)
        try container.encode(createdAtBeforeOrEqual, forKey: .createdAtBeforeOrEqual)
        try container.encode(id, forKey: .id)
        try container.encode(limit, forKey: .limit)
        try container.encode(offset, forKey: .offset)
        try container.encode(userId, forKey: .userId)
        try container.encode(userIdGt, forKey: .userIdGt)
        try container.encode(userIdGte, forKey: .userIdGte)
        try container.encode(userIdLt, forKey: .userIdLt)
        try container.encode(userIdLte, forKey: .userIdLte)
        try container.encode(members, forKey: .members)
        try container.encode(sort, forKey: .sort)
        try container.encode(user, forKey: .user)
    }
}
