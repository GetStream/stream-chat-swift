//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

struct GuestUserTokenRequestPayload<ExtraData: UserExtraData>: Encodable {
    private enum CodingKeys: String, CodingKey {
        case userId = "id"
    }

    let userId: UserId
    let extraData: ExtraData

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(userId, forKey: .userId)
        try extraData.encode(to: encoder)
    }
}
