//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// Generated properties are slightly different from the previously hand-written ones.
extension MutedChannelPayload {
    convenience init(
        mutedChannel: ChannelDetailPayload?,
        user: UserPayload?,
        createdAt: Date,
        updatedAt: Date,
        expiresAt: Date? = nil
    ) {
        self.init(
            channel: mutedChannel,
            createdAt: createdAt,
            expires: expiresAt,
            updatedAt: updatedAt,
            user: user
        )
    }
}
