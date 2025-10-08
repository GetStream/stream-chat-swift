//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension ChatUser {
    public static var unique: ChatUser {
        .mock(
            id: .unique,
            isOnline: true,
            isBanned: true,
            userRole: .user,
            createdAt: .unique,
            updatedAt: .unique,
            lastActiveAt: .unique,
            teams: [],
            extraData: [:]
        )
    }
}
