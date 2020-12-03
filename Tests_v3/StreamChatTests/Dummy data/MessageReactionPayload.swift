//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension MessageReactionPayload {
    static func dummy<T: ExtraDataTypes>(
        type: MessageReactionType = .init(rawValue: .unique),
        messageId: String,
        user: UserPayload<T.User>,
        extraData: T.MessageReaction = .defaultValue
    ) -> MessageReactionPayload<T> {
        .init(
            type: type,
            score: .random(in: 0...10),
            messageId: messageId,
            createdAt: .unique,
            updatedAt: .unique,
            user: user,
            extraData: extraData
        )
    }
}
