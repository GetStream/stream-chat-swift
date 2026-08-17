//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension DeleteChannelResponse {
    static func dummy(
        channel: ChannelDetailPayload? = .dummy()
    ) -> DeleteChannelResponse {
        DeleteChannelResponse(
            channel: channel
        )
    }
}
