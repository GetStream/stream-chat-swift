//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing a message reaction. `ChatMessageReaction` is an immutable snapshot
/// of a message reaction entity at the given time.
public struct ChatMessageReaction: Hashable {
    /// The reaction type.
    public let type: MessageReactionType
    
    /// The reaction score.
    public let score: Int
    
    /// The date the reaction was created.
    public let createdAt: Date
    
    /// The date the reaction was last updated.
    public let updatedAt: Date
    
    /// Custom data
    public let extraData: [String: RawJSON]
    
    /// The author.
    public let author: ChatUser
}
