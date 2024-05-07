//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// The information about a thread read.
package struct ThreadRead {
    /// The user which the read belongs to.
    internal let user: ChatUser
    /// The date when the user last read the thread.
    internal let lastReadAt: Date?
    /// The amount of messages unread.
    internal let unreadMessagesCount: Int
}
