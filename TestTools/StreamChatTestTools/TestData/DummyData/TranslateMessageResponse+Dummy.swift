//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension TranslateMessageResponse {
    static func dummy(message: MessagePayload = .dummy()) -> TranslateMessageResponse {
        TranslateMessageResponse(message: message)
    }
}
