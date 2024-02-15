//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension Reaction {
    static func dummy(
        type: MessageReactionType = .init(rawValue: .unique),
        messageId: String,
        user: UserObject,
        extraData: [String: RawJSON] = [:]
    ) -> Reaction {
        Reaction(
            createdAt: .unique,
            messageId: messageId,
            score: .random(in: 0...10),
            type: type.rawValue,
            updatedAt: .unique,
            custom: extraData,
            userId: user.id,
            user: user
        )
    }
}
