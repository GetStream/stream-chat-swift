//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension BanResponse {
    /// Returns dummy ban response with the given values.
    static func dummy(
        user: UserPayload? = .dummy(userId: .unique),
        bannedBy: UserPayload? = .dummy(userId: .unique),
        channel: ChannelDetailPayload? = .dummy(),
        createdAt: Date = .init(),
        expires: Date? = nil,
        reason: String? = nil,
        shadow: Bool? = nil
    ) -> BanResponse {
        .init(
            bannedBy: bannedBy,
            channel: channel,
            createdAt: createdAt,
            expires: expires,
            reason: reason,
            shadow: shadow,
            user: user
        )
    }
}
