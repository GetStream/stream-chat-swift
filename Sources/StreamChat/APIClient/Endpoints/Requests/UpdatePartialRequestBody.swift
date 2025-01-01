//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

struct UpdatePollPartialRequestBody: Codable, Hashable {
    let pollId: String
    var unset: [String]?
    var set: [String: RawJSON]?

    init(pollId: String, unset: [String]? = nil, set: [String: RawJSON]? = nil) {
        self.pollId = pollId
        self.unset = unset
        self.set = set
    }
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case pollId = "poll_id"
        case unset
        case set
    }
}
