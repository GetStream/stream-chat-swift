//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension TruncateChannelResponse {
    static func dummy(
        channel: ChannelDetailPayload? = nil,
        message: MessagePayload? = nil
    ) -> TruncateChannelResponse {
        TruncateChannelResponse(
            channel: channel,
            message: message
        )
    }
}
