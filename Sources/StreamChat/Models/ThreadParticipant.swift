//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// The details of a participant in a thread.
public struct ThreadParticipant: Equatable {
    /// The user information of the participant.
    public let user: ChatUser
    /// The id of the thread, which is also the id of the parent message.
    public let threadId: String
    /// The date when the participant joined.
    public let createdAt: Date
    /// The date when the participant last read the thread.
    public let lastReadAt: Date?
}
