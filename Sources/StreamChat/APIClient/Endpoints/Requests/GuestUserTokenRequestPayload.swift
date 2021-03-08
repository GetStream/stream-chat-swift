//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

struct GuestUserTokenRequestPayload<ExtraData: UserExtraData>: Encodable {
    private enum CodingKeys: String, CodingKey {
        case userId = "id"
        case name
        case imageURL = "image"
    }

    let userId: UserId
    let name: String?
    let imageURL: URL?
    let extraData: ExtraData

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try extraData.encode(to: encoder)
    }
}
