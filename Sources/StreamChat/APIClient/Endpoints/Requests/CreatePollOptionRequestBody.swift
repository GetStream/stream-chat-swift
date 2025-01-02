//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

struct CreatePollOptionRequestBody: Codable, Hashable {
    let pollId: String
    let text: String
    var position: Int?
    var custom: [String: RawJSON]?

    init(pollId: String, text: String, position: Int? = nil, custom: [String: RawJSON]? = nil) {
        self.pollId = pollId
        self.text = text
        self.position = position
        self.custom = custom
    }
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case pollId = "poll_id"
        case text
        case position
        case custom
    }
}
