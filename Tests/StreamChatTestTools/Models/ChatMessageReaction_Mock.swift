//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension ChatMessageReaction {
    public static func mock(
        type: MessageReactionType,
        score: Int = 1,
        createdAt: Date = .distantPast,
        updatedAt: Date = .distantPast,
        author: ChatUser = ChatUser.mock(id: "luke"),
        extraData: [String: RawJSON] = [:]
    ) -> ChatMessageReaction {
        .init(
            type: type,
            score: score,
            createdAt: createdAt,
            updatedAt: updatedAt,
            author: author,
            extraData: extraData
        )
    }
}
