//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// Extra glue for reducing the git diff: the generated model nests the custom data
// under `custom` and orders its init differently from the previously hand-written
// MessageReactionPayload. Keep for now and clean up gradually.
extension MessageReactionPayload {
    var extraData: [String: RawJSON] { custom }

    convenience init(
        type: MessageReactionType,
        score: Int,
        messageId: String,
        createdAt: Date,
        updatedAt: Date,
        user: UserPayload,
        extraData: [String: RawJSON]
    ) {
        self.init(
            createdAt: createdAt,
            custom: extraData,
            messageId: messageId,
            score: score,
            type: type,
            updatedAt: updatedAt,
            user: user,
            userId: user.id
        )
    }
}
