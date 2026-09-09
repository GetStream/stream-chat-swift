//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension BanResponse {
    func asModel() -> BannedUser? {
        guard let user = user else { return nil }

        return BannedUser(
            user: user.asModel(),
            bannedBy: bannedBy?.asModel(),
            cid: channel?.cid,
            createdAt: createdAt,
            expiresAt: expires,
            reason: reason,
            isShadowBan: shadow ?? false
        )
    }
}
