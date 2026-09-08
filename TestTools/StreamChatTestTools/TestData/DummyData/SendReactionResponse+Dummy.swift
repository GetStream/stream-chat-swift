//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension SendReactionResponse {
    static func dummy(message: MessagePayload, reaction: MessageReactionPayload) -> SendReactionResponse {
        .init(message: message, reaction: reaction)
    }
}

extension DeleteReactionResponse {
    static func dummy(message: MessagePayload, reaction: MessageReactionPayload) -> DeleteReactionResponse {
        .init(message: message, reaction: reaction)
    }
}
