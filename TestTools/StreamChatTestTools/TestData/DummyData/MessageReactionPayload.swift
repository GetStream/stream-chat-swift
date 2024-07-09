//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension MessageReactionPayload {
    static func dummy(
        type: MessageReactionType = .init(rawValue: .unique),
        score: Int = .random(in: 0...10),
        messageId: String,
        createdAt: Date = .unique,
        updatedAt: Date = .unique,
        user: UserPayload,
        extraData: [String: RawJSON] = [:]
    ) -> MessageReactionPayload {
        .init(
            type: type,
            score: score,
            messageId: messageId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            user: user,
            extraData: extraData
        )
    }
}
