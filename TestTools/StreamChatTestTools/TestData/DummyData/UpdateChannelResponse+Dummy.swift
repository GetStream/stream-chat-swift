//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension UpdateChannelResponse {
    static func dummy(
        channel: ChannelDetailPayload? = nil,
        members: [MemberPayload] = [],
        message: MessagePayload? = nil
    ) -> UpdateChannelResponse {
        UpdateChannelResponse(
            channel: channel,
            members: members,
            message: message
        )
    }
}
