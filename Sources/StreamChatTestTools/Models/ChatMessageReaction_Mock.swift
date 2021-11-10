//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension ChatMessageReaction {
    public static func mock(
        type: MessageReactionType = "like",
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
