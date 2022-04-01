//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension TypingEventDTO {
    static var unique: TypingEventDTO = try!
        .init(
            from: EventPayload(
                eventType: .userStartTyping,
                user: .dummy(userId: .unique),
                channel: .dummy(cid: .unique)
            )
        )

    static func startTyping(
        cid: ChannelId = .unique,
        userId: UserId = .unique
    ) -> TypingEventDTO {
        let payload = EventPayload(
            eventType: .userStartTyping,
            cid: cid,
            user: .dummy(userId: userId),
            createdAt: .unique
        )

        return try! .init(from: payload)
    }

    static func stopTyping(cid: ChannelId = .unique, userId: UserId = .unique) -> TypingEventDTO {
        let payload = EventPayload(
            eventType: .userStopTyping,
            cid: cid,
            user: .dummy(userId: userId),
            createdAt: .unique
        )

        return try! .init(from: payload)
    }
}

extension TypingEventDTO: Equatable {
    public static func == (lhs: TypingEventDTO, rhs: TypingEventDTO) -> Bool {
        lhs.isTyping == rhs.isTyping && lhs.cid == rhs.cid && lhs.user.id == rhs.user.id
    }
}
