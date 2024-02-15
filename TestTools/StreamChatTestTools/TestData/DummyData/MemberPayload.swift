//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension ChannelMember {
    /// Returns a dummy member payload with the given `userId` and `role`
    static func dummy(
        user: UserObject = .dummy(userId: .unique),
        createdAt: Date = .unique,
        updatedAt: Date = .unique,
        lastActive: Date = .unique,
        role: MemberRole = .member,
        isMemberBanned: Bool = false
    ) -> ChannelMember {
        ChannelMember(
            banned: isMemberBanned, 
            channelRole: role.rawValue,
            createdAt: createdAt,
            shadowBanned: false,
            updatedAt: updatedAt,
            userId: user.id, 
            user: user
        )
    }
}
