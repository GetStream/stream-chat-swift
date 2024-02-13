//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct QueryChannelsRequest: Codable, Hashable {
    public var connectionId: String? = nil
    public var limit: Int? = nil
    public var memberLimit: Int? = nil
    public var messageLimit: Int? = nil
    public var offset: Int? = nil
    public var presence: Bool? = nil
    public var state: Bool? = nil
    public var userId: String? = nil
    public var watch: Bool? = nil
    public var sort: [SortParamRequest?]? = nil
    public var filterConditions: [String: RawJSON]? = nil
    public var user: UserObjectRequest? = nil

    public init(connectionId: String? = nil, limit: Int? = nil, memberLimit: Int? = nil, messageLimit: Int? = nil, offset: Int? = nil, presence: Bool? = nil, state: Bool? = nil, userId: String? = nil, watch: Bool? = nil, sort: [SortParamRequest?]? = nil, filterConditions: [String: RawJSON]? = nil, user: UserObjectRequest? = nil) {
        self.connectionId = connectionId
        self.limit = limit
        self.memberLimit = memberLimit
        self.messageLimit = messageLimit
        self.offset = offset
        self.presence = presence
        self.state = state
        self.userId = userId
        self.watch = watch
        self.sort = sort
        self.filterConditions = filterConditions
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case connectionId = "connection_id"
        case limit
        case memberLimit = "member_limit"
        case messageLimit = "message_limit"
        case offset
        case presence
        case state
        case userId = "user_id"
        case watch
        case sort
        case filterConditions = "filter_conditions"
        case user
    }
}
