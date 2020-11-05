//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

open class ChatUIMessageReaction {
    /// The reaction type.
    public let type: MessageReactionType
    
    /// The reaction score.
    public let score: Int
    
    /// The date the reaction was created.
    public let createdAt: Date
    
    /// The date the reaction was last updated.
    public let updatedAt: Date
    
    /// The author.
    public let author: ChatUIUser
    
    public required init<ExtraData: ExtraDataTypes>(config: UIModelConfig = .default, reaction: _ChatMessageReaction<ExtraData>) {
        type = reaction.type
        score = reaction.score
        createdAt = reaction.createdAt
        updatedAt = reaction.updatedAt
        author = config.userModelType.init(
            user: reaction.author,
            name: reaction.author.name,
            imageURL: reaction.author.imageURL
        )
    }
}

extension ChatUIMessageReaction: Hashable {
    public static func == (lhs: ChatUIMessageReaction, rhs: ChatUIMessageReaction) -> Bool {
        lhs.type == rhs.type
            && lhs.score == rhs.score
            && lhs.createdAt == rhs.createdAt
            && lhs.updatedAt == rhs.updatedAt
            && lhs.author == rhs.author
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(author.id)
    }
}
