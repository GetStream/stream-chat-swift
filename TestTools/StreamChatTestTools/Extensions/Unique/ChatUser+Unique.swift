//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension ChatUser {
    static public var unique: ChatUser {
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
