//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension TypingStartEventDTO {
    static let unique: TypingStartEventDTO = .startTyping()

    static func startTyping(
        cid: ChannelId = .unique,
        userId: UserId = .unique
    ) -> TypingStartEventDTO {
        TypingStartEventDTO(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            custom: [:],
            user: UserResponseCommonFields(.dummy(userId: userId))
        )
    }
}

extension TypingStopEventDTO {
    static func stopTyping(cid: ChannelId = .unique, userId: UserId = .unique) -> TypingStopEventDTO {
        TypingStopEventDTO(
            channelId: cid.id,
            channelType: cid.type.rawValue,
            cid: cid.rawValue,
            createdAt: .unique,
            custom: [:],
            user: UserResponseCommonFields(.dummy(userId: userId))
        )
    }
}
