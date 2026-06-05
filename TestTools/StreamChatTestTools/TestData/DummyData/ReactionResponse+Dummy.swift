//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension ReactionResponse {
    static func dummy(
        type: MessageReactionType = .init(rawValue: .unique),
        score: Int = .random(in: 0...10),
        messageId: String,
        createdAt: Date = .unique,
        updatedAt: Date = .unique,
        user: UserResponse,
        extraData: [String: RawJSON] = [:]
    ) -> ReactionResponse {
        .init(
            createdAt: createdAt,
            custom: extraData,
            messageId: messageId,
            score: score,
            type: type.rawValue,
            updatedAt: updatedAt,
            user: user,
            userId: user.id
        )
    }
}
