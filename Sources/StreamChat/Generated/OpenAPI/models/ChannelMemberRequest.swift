//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChannelMemberRequest: Sendable, Encodable, JSONEncodable {
    let custom: [String: RawJSON]?
    let userId: String?

    init(custom: [String: RawJSON]? = nil, userId: String? = nil) {
        self.custom = custom
        self.userId = userId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        case userId = "user_id"
    }
}
