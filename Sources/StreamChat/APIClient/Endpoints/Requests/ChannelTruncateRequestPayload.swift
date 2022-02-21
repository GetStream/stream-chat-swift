//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

struct ChannelTruncateRequestPayload: Encodable {
    private enum CodingKeys: String, CodingKey {
        case skipPush = "skip_push"
        case hardDelete = "hard_delete"
        case message
    }

    /// If `true`, skips sending push notification
    let skipPush: Bool
    /// If `true`, messages are hard deleted from the channel. Otherwise they're marked as hidden.
    let hardDelete: Bool
    /// Optional system message
    let message: MessageRequestBody?
}
