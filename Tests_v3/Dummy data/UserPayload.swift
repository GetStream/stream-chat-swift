//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatClient

extension UserPayload where ExtraData == NameAndImageExtraData {
    /// Returns a dummy user payload with the given UserId
    static func dummy(userId: UserId) -> UserPayload {
        let lukeExtraData = NameAndImageExtraData(name: "Luke", imageURL: URL(string: UUID().uuidString))
        
        return .init(
            id: userId,
            role: .admin,
            createdAt: .unique,
            updatedAt: .unique,
            lastActiveAt: .unique,
            isOnline: true,
            isInvisible: true,
            isBanned: true,
            teams: [],
            extraData: lukeExtraData
        )
    }
}
