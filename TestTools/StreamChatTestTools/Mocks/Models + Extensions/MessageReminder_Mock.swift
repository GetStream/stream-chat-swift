//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public extension MessageReminder {
    static func mock(
        id: String = .unique,
        remindAt: Date? = nil,
        message: ChatMessage = .mock(),
        channel: ChatChannel = .mock(cid: .unique),
        createdAt: Date = .init(),
        updatedAt: Date = .init()
    ) -> MessageReminder {
        .init(
            id: id,
            remindAt: remindAt,
            message: message,
            channel: channel,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
