//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// The details of a participant in a thread.
package struct ThreadParticipant {
    /// The user information of the participant.
    internal let user: ChatUser
    /// The id of the thread, which is also the id of the parent message.
    internal let threadId: String
    /// The date when the participant joined.
    internal let createdAt: Date
    /// The date when the participant last read the thread.
    internal let lastReadAt: Date?
}
