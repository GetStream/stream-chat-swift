//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// A unique identifier of a message.
public typealias MessageId = String

/// A type representing a chat message. `ChatMessage` is an immutable snapshot of a chat message entity at the given time.
///
/// - Note: `ChatMessage` is a typealias of `_ChatMessage` with default extra data. If you're using custom extra data,
/// create your own typealias of `_ChatMessage`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public typealias ChatMessage = _ChatMessage<NoExtraData>

/// A type representing a chat message. `_ChatMessage` is an immutable snapshot of a chat message entity at the given time.
///
/// - Note: `_ChatMessage` type is not meant to be used directly. If you're using default extra data, use `ChatMessage`
/// typealias instead. If you're using custom extra data, create your own typealias of `_ChatMessage`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
@dynamicMemberLookup
public struct _ChatMessage<ExtraData: ExtraDataTypes> {
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
    
    /// Additional data associated with the message.
    ///
    /// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
    ///
    public let extraData: ExtraData.Message
    
    /// Quoted message.
    ///
    /// If message is inline reply this property will contain the message quoted by this reply.
    ///
    public var quotedMessage: _ChatMessage<ExtraData>? { _quotedMessage }

    @CoreDataLazy internal var _quotedMessage: _ChatMessage<ExtraData>?
    
    /// A flag indicating whether the message is a silent message.
    ///
    /// Silent messages are special messages that don't increase the unread messages count nor mark a channel as unread.
    ///
    public let isSilent: Bool
    
    /// The reactions to the message created by any user.
    public let reactionScores: [MessageReactionType: Int]
    
    /// The user which is the author of the message.
    ///
    /// - Important: The `author` property is loaded and evaluated lazily to maintain high performance.
    public var author: _ChatUser<ExtraData.User> { _author }
    
    @CoreDataLazy internal var _author: _ChatUser<ExtraData.User>
    
    /// A list of users that are mentioned in this message.
    ///
    /// - Important: The `mentionedUsers` property is loaded and evaluated lazily to maintain high performance.
    public var mentionedUsers: Set<_ChatUser<ExtraData.User>> { _mentionedUsers }
    
    @CoreDataLazy internal var _mentionedUsers: Set<_ChatUser<ExtraData.User>>

    /// A list of users that participated in this message thread
    public var threadParticipants: Set<_ChatUser<ExtraData.User>> { _threadParticipants }
    
    @CoreDataLazy internal var _threadParticipants: Set<_ChatUser<ExtraData.User>>
    
    /// A list of attachments in this message.
    ///
    /// - Important: The `attachments` property is loaded and evaluated lazily to maintain high performance.
    public var attachments: [ChatMessageAttachment] { _attachments }
    
    @CoreDataLazy internal var _attachments: [ChatMessageAttachment]
        
    /// A list of latest 25 replies to this message.
    ///
    /// - Important: The `latestReplies` property is loaded and evaluated lazily to maintain high performance.
    public var latestReplies: [_ChatMessage<ExtraData>] { _latestReplies }
    
    @CoreDataLazy internal var _latestReplies: [_ChatMessage<ExtraData>]
    
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
    /// - Important: The `latestReactions` property is loaded and evaluated lazily to maintain high performance.
    public var latestReactions: Set<_ChatMessageReaction<ExtraData>> { _latestReactions }
    
    @CoreDataLazy internal var _latestReactions: Set<_ChatMessageReaction<ExtraData>>
    
    /// The entire list of reactions to the message left by the current user.
    ///
    /// - Important: The `currentUserReactions` property is loaded and evaluated lazily to maintain high performance.
    public var currentUserReactions: Set<_ChatMessageReaction<ExtraData>> { _currentUserReactions }
    
    @CoreDataLazy internal var _currentUserReactions: Set<_ChatMessageReaction<ExtraData>>
    
    /// `true` if the author of the message is the currently logged-in user.
    public let isSentByCurrentUser: Bool

    /// The message pinning information. Is `nil` if the message is not pinned.
    public let pinDetails: _MessagePinDetails<ExtraData>?
    
    internal init(
        id: MessageId,
        text: String,
        type: MessageType,
        command: String?,
        createdAt: Date,
        locallyCreatedAt: Date?,
        updatedAt: Date,
        deletedAt: Date?,
        arguments: String?,
        parentMessageId: MessageId?,
        showReplyInChannel: Bool,
        replyCount: Int,
        extraData: ExtraData.Message,
        quotedMessage: @escaping () -> _ChatMessage<ExtraData>?,
        isSilent: Bool,
        reactionScores: [MessageReactionType: Int],
        author: @escaping () -> _ChatUser<ExtraData.User>,
        mentionedUsers: @escaping () -> Set<_ChatUser<ExtraData.User>>,
        threadParticipants: @escaping () -> Set<_ChatUser<ExtraData.User>>,
        attachments: @escaping () -> [ChatMessageAttachment],
        latestReplies: @escaping () -> [_ChatMessage<ExtraData>],
        localState: LocalMessageState?,
        isFlaggedByCurrentUser: Bool,
        latestReactions: @escaping () -> Set<_ChatMessageReaction<ExtraData>>,
        currentUserReactions: @escaping () -> Set<_ChatMessageReaction<ExtraData>>,
        isSentByCurrentUser: Bool,
        pinDetails: _MessagePinDetails<ExtraData>?,
        underlyingContext: NSManagedObjectContext?
    ) {
        self.id = id
        self.text = text
        self.type = type
        self.command = command
        self.createdAt = createdAt
        self.locallyCreatedAt = locallyCreatedAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.arguments = arguments
        self.parentMessageId = parentMessageId
        self.showReplyInChannel = showReplyInChannel
        self.replyCount = replyCount
        self.extraData = extraData
        self.isSilent = isSilent
        self.reactionScores = reactionScores
        self.localState = localState
        self.isFlaggedByCurrentUser = isFlaggedByCurrentUser
        self.isSentByCurrentUser = isSentByCurrentUser
        self.pinDetails = pinDetails
        
        self.$_author = (author, underlyingContext)
        self.$_mentionedUsers = (mentionedUsers, underlyingContext)
        self.$_threadParticipants = (threadParticipants, underlyingContext)
        self.$_attachments = (attachments, underlyingContext)
        self.$_latestReplies = (latestReplies, underlyingContext)
        self.$_latestReactions = (latestReactions, underlyingContext)
        self.$_currentUserReactions = (currentUserReactions, underlyingContext)
        self.$_quotedMessage = (quotedMessage, underlyingContext)
    }
}

extension _ChatMessage {
    /// Indicates whether the message is pinned or not.
    public var isPinned: Bool {
        pinDetails != nil
    }
}

extension _ChatMessage: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public extension _ChatMessage {
    subscript<T>(dynamicMember keyPath: KeyPath<ExtraData.Message, T>) -> T {
        extraData[keyPath: keyPath]
    }
}

/// A type of the message.
public enum MessageType: String, Codable {
    /// A regular message created in the channel.
    case regular
    
    /// A temporary message which is only delivered to one user. It is not stored in the channel history. Ephemeral messages
    /// are normally used by commands (e.g. /giphy) to prompt messages or request for actions.
    case ephemeral
    
    /// An error message generated as a result of a failed command. It is also ephemeral, as it is not stored in the channel
    /// history and is only delivered to one user.
    case error
    
    /// The message is a reply to another message. Use the `parentMessageId` variable of the message to get the parent
    /// message data.
    case reply
    
    /// A message generated by a system event, like updating the channel or muting a user.
    case system
    
    /// A deleted message.
    case deleted
}

// The pinning information of a message.
public struct _MessagePinDetails<ExtraData: ExtraDataTypes> {
    /// Date when the message got pinned
    public let pinnedAt: Date

    /// The user that pinned the message
    public let pinnedBy: _ChatUser<ExtraData.User>

    /// Date when the message pin expires. An nil value means that message does not expire
    public let expiresAt: Date
}

/// A possible additional local state of the message. Applies only for the messages of the current user.
public enum LocalMessageState: String {
    /// The message is waiting to be synced.
    case pendingSync
    /// The message is currently being synced
    case syncing
    /// Syncing of the message failed after multiple of tries. The system is not trying to sync this message anymore.
    case syncingFailed
    
    /// The message is waiting to be sent.
    case pendingSend
    /// The message is currently being sent to the servers.
    case sending
    /// Sending of the message failed after multiple of tries. The system is not trying to send this message anymore.
    case sendingFailed
    
    /// The message is waiting to be deleted.
    case deleting
    /// Deleting of the message failed after multiple of tries. The system is not trying to delete this message anymore.
    case deletingFailed
}

/// You need to make your custom type conforming to this protocol if you want to use it for extending `ChatMessage` entity with
/// your custom additional data.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public protocol MessageExtraData: ExtraData {}
