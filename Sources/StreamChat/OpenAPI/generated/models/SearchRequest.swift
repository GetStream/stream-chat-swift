//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct SearchRequest: Codable, Hashable {
    public var filterConditions: [String: RawJSON]
    public var limit: Int? = nil
    public var next: String? = nil
    public var offset: Int? = nil
    public var query: String? = nil
    public var sort: [SortParam?]? = nil
    public var messageFilterConditions: [String: RawJSON]? = nil

    public init(filterConditions: [String: RawJSON], limit: Int? = nil, next: String? = nil, offset: Int? = nil, query: String? = nil, sort: [SortParam?]? = nil, messageFilterConditions: [String: RawJSON]? = nil) {
        self.filterConditions = filterConditions
        self.limit = limit
        self.next = next
        self.offset = offset
        self.query = query
        self.sort = sort
        self.messageFilterConditions = messageFilterConditions
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case filterConditions = "filter_conditions"
        case limit
        case next
        case offset
        case query
        case sort
        case messageFilterConditions = "message_filter_conditions"
    }
}
