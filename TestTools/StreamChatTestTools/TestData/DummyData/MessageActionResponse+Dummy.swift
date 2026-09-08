//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension MessageActionResponse {
    static func dummy(
        message: MessagePayload? = .dummy()
    ) -> MessageActionResponse {
        MessageActionResponse(
            message: message
        )
    }
}
