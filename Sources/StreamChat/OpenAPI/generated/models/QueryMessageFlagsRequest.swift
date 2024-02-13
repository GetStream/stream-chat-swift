//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct QueryMessageFlagsRequest: Codable, Hashable {
    public var limit: Int? = nil
    public var offset: Int? = nil
    public var showDeletedMessages: Bool? = nil
    public var userId: String? = nil
    public var sort: [SortParam?]? = nil
    public var filterConditions: [String: RawJSON]? = nil
    public var user: UserObject? = nil

    public init(limit: Int? = nil, offset: Int? = nil, showDeletedMessages: Bool? = nil, userId: String? = nil, sort: [SortParam?]? = nil, filterConditions: [String: RawJSON]? = nil, user: UserObject? = nil) {
        self.limit = limit
        self.offset = offset
        self.showDeletedMessages = showDeletedMessages
        self.userId = userId
        self.sort = sort
        self.filterConditions = filterConditions
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case limit
        case offset
        case showDeletedMessages = "show_deleted_messages"
        case userId = "user_id"
        case sort
        case filterConditions = "filter_conditions"
        case user
    }
}
