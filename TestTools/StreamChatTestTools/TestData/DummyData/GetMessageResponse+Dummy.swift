//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension GetMessageResponse {
    static func dummy(
        message: MessageWithChannelResponse = .dummy()
    ) -> GetMessageResponse {
        GetMessageResponse(
            message: message
        )
    }
}
