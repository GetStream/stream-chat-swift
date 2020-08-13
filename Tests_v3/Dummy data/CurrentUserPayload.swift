//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatClient

extension CurrentUserPayload {
    /// Returns a dummy user payload with the given userId, role, and extraData
    static func dummy(userId: UserId, role: UserRole, extraData: ExtraData) -> CurrentUserPayload {
        .init(id: userId,
              role: role,
              createdAt: .unique,
              updatedAt: .unique,
              lastActiveAt: .unique,
              isOnline: true,
              isInvisible: true,
              isBanned: true,
              teams: [],
              extraData: extraData)
    }
}
