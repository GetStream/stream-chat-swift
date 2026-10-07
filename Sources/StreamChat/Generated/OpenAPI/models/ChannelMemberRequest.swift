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

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(custom, forKey: .custom)
        try container.encodeIfPresent(userId, forKey: .userId)
    }
}
