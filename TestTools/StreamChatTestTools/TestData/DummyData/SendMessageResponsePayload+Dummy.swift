//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension SendMessageResponsePayload {
    static func dummy(message: MessagePayload) -> SendMessageResponsePayload {
        .init(message: message)
    }
}

extension UpdateMessageResponse {
    static func dummy(message: MessagePayload) -> UpdateMessageResponse {
        .init(message: message)
    }
}

extension UpdateMessagePartialResponse {
    static func dummy(message: MessagePayload?) -> UpdateMessagePartialResponse {
        .init(message: message)
    }
}

extension CreateDraftResponse {
    static func dummy(draft: DraftPayload) -> CreateDraftResponse {
        .init(draft: draft)
    }
}
