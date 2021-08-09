//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension MessageReactionPayload {
    static func dummy(
        type: MessageReactionType = .init(rawValue: .unique),
        messageId: String,
        user: UserPayload,
        extraData: [String: RawJSON] = [:]
    ) -> MessageReactionPayload {
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
