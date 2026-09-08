//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension SendReactionRequest {
    convenience init(
        enforceUnique: Bool,
        extraData: [String: RawJSON],
        pushEmojiCode: String?,
        score: Int,
        skipPush: Bool,
        type: MessageReactionType
    ) {
        var custom = extraData
        if let pushEmojiCode {
            custom["emoji_code"] = .string(pushEmojiCode)
        }
        self.init(
            enforceUnique: enforceUnique,
            reaction: ReactionRequest(
                custom: custom,
                score: score,
                type: type
            ),
            skipPush: skipPush
        )
    }
}
