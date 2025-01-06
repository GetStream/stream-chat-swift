//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

struct QueryPollsRequestBody: Encodable {
    var limit: Int?
    var next: String?
    var prev: String?
    var sort: [SortParamRequest?]?
    var filter: [String: RawJSON]?

    init(
        limit: Int? = nil,
        next: String? = nil,
        prev: String? = nil,
        sort: [SortParamRequest?]? = nil,
        filter: [String: RawJSON]? = nil
    ) {
        self.limit = limit
        self.next = next
        self.prev = prev
        self.sort = sort
        self.filter = filter
    }
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case limit
        case next
        case prev
        case sort
        case filter
    }
}

struct SortParamRequest: Encodable {
    var direction: Int?
    var field: String?

    init(direction: Int? = nil, field: String? = nil) {
        self.direction = direction
        self.field = field
    }
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case direction
        case field
    }
}

struct QueryPollVotesRequestBody: Encodable {
    let pollId: String
    var limit: Int?
    var next: String?
    var prev: String?
    var sort: [SortParamRequest?]?
    var filter: [String: RawJSON]?

    init(
        pollId: String,
        limit: Int? = nil,
        next: String? = nil,
        prev: String? = nil,
        sort: [SortParamRequest?]? = nil,
        filter: [String: RawJSON]? = nil
    ) {
        self.pollId = pollId
        self.limit = limit
        self.next = next
        self.prev = prev
        self.sort = sort
        self.filter = filter
    }
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case pollId = "poll_id"
        case limit
        case next
        case prev
        case sort
        case filter
    }
}
