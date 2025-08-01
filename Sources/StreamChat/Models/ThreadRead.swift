//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// The information about a thread read.
public struct ThreadRead: Equatable, Sendable {
    /// The user which the read belongs to.
    public let user: ChatUser
    /// The date when the user last read the thread.
    public let lastReadAt: Date?
    /// The amount of messages unread.
    public let unreadMessagesCount: Int
}
