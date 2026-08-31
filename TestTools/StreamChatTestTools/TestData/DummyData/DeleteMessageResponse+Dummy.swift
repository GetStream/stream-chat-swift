//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension DeleteMessageResponse {
    static func dummy(
        message: MessagePayload = .dummy()
    ) -> DeleteMessageResponse {
        DeleteMessageResponse(
            message: message
        )
    }
}
