//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatClient

extension MemberPayload where ExtraData == NameAndImageExtraData {
    /// Returns a dummy member payload with the given `userId` and `role`
    static func dummy(userId: UserId = .unique, role: MemberRole = .member) -> MemberPayload {
        .init(
            user: .dummy(userId: userId),
            role: role,
            createdAt: .unique,
            updatedAt: .unique
        )
    }
}
