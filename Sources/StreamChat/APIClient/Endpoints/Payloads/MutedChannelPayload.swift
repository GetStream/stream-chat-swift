//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object describing the incoming muted-user JSON payload.
struct MutedChannelPayload<ExtraData: ExtraDataTypes>: Decodable {
    private enum CodingKeys: String, CodingKey {
        case mutedChannel = "channel"
        case user
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    let mutedChannel: ChannelDetailPayload<ExtraData>
    let user: UserPayload<ExtraData.User>
    let createdAt: Date
    let updatedAt: Date
}
