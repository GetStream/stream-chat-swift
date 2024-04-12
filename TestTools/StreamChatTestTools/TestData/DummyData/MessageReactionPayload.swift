//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension MessageReactionPayload {
    static func dummy(
        type: MessageReactionType = .init(rawValue: .unique),
        messageId: String,
        updatedAt: Date = .unique,
        user: UserPayload,
        extraData: [String: RawJSON] = [:]
    ) -> MessageReactionPayload {
        .init(
            type: type,
            score: .random(in: 0...10),
            messageId: messageId,
            createdAt: .unique,
            updatedAt: updatedAt,
            user: user,
            extraData: extraData
        )
    }
}
