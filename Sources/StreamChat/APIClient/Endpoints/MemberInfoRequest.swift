//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

struct MemberInfoRequest: Encodable {
    let userId: UserId
    let extraData: [String: RawJSON]?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case extraData
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try extraData?.encode(to: encoder)
    }
}
