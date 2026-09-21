//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public extension BannedUser {
    static func mock(
        user: ChatUser = .mock(id: .unique),
        bannedBy: ChatUser? = nil,
        cid: ChannelId? = nil,
        createdAt: Date = .init(),
        expiresAt: Date? = nil,
        reason: String? = nil,
        isShadowBan: Bool = false
    ) -> BannedUser {
        .init(
            user: user,
            bannedBy: bannedBy,
            cid: cid,
            createdAt: createdAt,
            expiresAt: expiresAt,
            reason: reason,
            isShadowBan: isShadowBan
        )
    }
}
