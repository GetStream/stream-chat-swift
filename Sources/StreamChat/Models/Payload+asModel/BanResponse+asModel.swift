//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension BanResponse {
    /// Converts the BanResponse to a BannedUser model.
    /// - Returns: A BannedUser instance, or nil if the banned user is missing.
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
