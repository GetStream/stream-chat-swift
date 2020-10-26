//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Foundation

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
