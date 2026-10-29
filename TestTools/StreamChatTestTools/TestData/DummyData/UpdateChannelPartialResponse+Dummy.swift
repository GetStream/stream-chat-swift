//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension UpdateChannelPartialResponse {
    static func dummy(
        channel: ChannelDetailPayload? = nil,
        members: [MemberPayload] = []
    ) -> UpdateChannelPartialResponse {
        UpdateChannelPartialResponse(
            channel: channel,
            members: members
        )
    }
}
