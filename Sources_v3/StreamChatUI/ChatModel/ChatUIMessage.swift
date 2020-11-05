//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

open class ChatUIMessage {
    /// A unique identifier of the message.
    public let id: MessageId
    
    /// The text of the message.
    public let text: String
    
    /// A type of the message.
    public let type: MessageType
    
    /// If the message was created by a specific `/` command, the command is saved in this variable.
    public let command: String?
    
    /// Date when the message was created on the server. This date can differ from `locallyCreatedAt`.
    public let createdAt: Date
    
    /// Date when the message was created locally and scheduled to be send. Applies only for the messages of the current user.
    public let locallyCreatedAt: Date?
    
    /// A date when the message was updated last time.
    public let updatedAt: Date
    
    /// If the message was deleted, this variable contains a timestamp of that event, otherwise `nil`.
    public let deletedAt: Date?
    
    /// If the message was created by a specific `/` command, the arguments of the command are stored in this variable.
    public let arguments: String?
    
    /// The ID of the parent message, if the message is a reply, otherwise `nil`.
    public let parentMessageId: MessageId?
    
    /// If the message is a reply and this flag is `true`, the message should be also shown in the channel, not only in the
    /// reply thread.
    public let showReplyInChannel: Bool
    
    /// Contains the number of replies for this message.
    public let replyCount: Int
    
    /// A flag indicating whether the message is a silent message.
    ///
    /// Silent messages are special messages that don't increase the unread messages count nor mark a channel as unread.
    ///
    public let isSilent: Bool
    
    /// The reactions to the message created by any user.
    public let reactionScores: [MessageReactionType: Int]
    
    /// The user which is the author of the message.
    public let author: ChatUIUser
    
    /// A list of users that are mentioned in this message.
    public let mentionedUsers: Set<ChatUIUser>
    
    /// A list of latest 25 replies to this message.
    public let latestReplies: [ChatUIMessage]
    
    /// A possible additional local state of the message. Applies only for the messages of the current user.
    ///
    /// Most of the time this value is `nil`. This value is always `nil` for messages not from the current user. A typical
    /// use of this value is to check if a message is pending send/delete, and update the UI accordingly.
    ///
    public let localState: LocalMessageState?
    
    /// An indicator whether the message is flagged by the current user.
    ///
    /// - Note: Please be aware that the value of this field is not persisted on the server,
    /// and is valid only locally for the current session.
    public let isFlaggedByCurrentUser: Bool
    
    /// The latest reactions to the message created by any user.
    ///
    /// - Note: There can be `10` reactions at max.
    public let latestReactions: Set<ChatUIMessageReaction>
    
    /// The entire list of reactions to the message left by the current user.
    public let currentUserReactions: Set<ChatUIMessageReaction>
    
    public required init<ExtraData: ExtraDataTypes>(config: UIModelConfig = .default, message: _ChatMessage<ExtraData>) {
        id = message.id
        text = message.text
        type = message.type
        command = message.command
        createdAt = message.createdAt
        locallyCreatedAt = message.locallyCreatedAt
        updatedAt = message.updatedAt
        deletedAt = message.deletedAt
        arguments = message.arguments
        parentMessageId = message.parentMessageId
        showReplyInChannel = message.showReplyInChannel
        replyCount = message.replyCount
        isSilent = message.isSilent
        reactionScores = message.reactionScores
        author = config.userModelType.init(user: message.author, name: message.author.name, imageURL: message.author.imageURL)
        mentionedUsers = Set(
            message.mentionedUsers
                .map { config.userModelType.init(user: $0, name: $0.name, imageURL: $0.imageURL) }
        )
        latestReplies = message.latestReplies.map { config.messageModelType.init(config: config, message: $0) }
        localState = message.localState
        isFlaggedByCurrentUser = message.isFlaggedByCurrentUser
        latestReactions = Set(message.latestReactions.map { config.reactionModelType.init(config: config, reaction: $0) })
        currentUserReactions = Set(message.currentUserReactions.map { config.reactionModelType.init(config: config, reaction: $0) })
    }
}
