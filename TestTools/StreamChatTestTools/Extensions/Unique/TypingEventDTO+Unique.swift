//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension TypingStartEventDTO {
    static let unique: TypingStartEventDTO = .startTyping()

    static func startTyping(
        cid: ChannelId = .unique,
        userId: UserId = .unique,
        member: MemberInfoPayload? = nil
    ) -> TypingStartEventDTO {
        TypingStartEventDTO(
            cid: cid,
            createdAt: .unique,
            member: member,
            user: .dummy(userId: userId)
        )
    }
}

extension TypingStopEventDTO {
    static func stopTyping(cid: ChannelId = .unique, userId: UserId = .unique) -> TypingStopEventDTO {
        TypingStopEventDTO(
            cid: cid,
            createdAt: .unique,
            user: .dummy(userId: userId)
        )
    }
}

extension TypingStartEventDTO: Equatable {
    public static func == (lhs: TypingStartEventDTO, rhs: TypingStartEventDTO) -> Bool {
        lhs.cid == rhs.cid && lhs.user?.id == rhs.user?.id
    }
}

extension TypingStopEventDTO: Equatable {
    public static func == (lhs: TypingStopEventDTO, rhs: TypingStopEventDTO) -> Bool {
        lhs.cid == rhs.cid && lhs.user?.id == rhs.user?.id
    }
}
