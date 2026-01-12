//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

struct UpdatePollOptionRequest: Encodable {
    let id: String
    let pollId: String
    let text: String
    var custom: [String: RawJSON]?

    init(id: String, pollId: String, text: String, custom: [String: RawJSON]? = nil) {
        self.id = id
        self.pollId = pollId
        self.text = text
        self.custom = custom
    }
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case pollId = "poll_id"
        case text
        case custom
    }
}
