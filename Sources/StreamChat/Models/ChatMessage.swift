//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// A unique identifier of a message.
public typealias MessageId = String

/// A type representing a chat message. `ChatMessage` is an immutable snapshot of a chat message entity at the given time.
public struct ChatMessage {
    /// A unique identifier of the message.
    public let id: MessageId

    /// The ChannelId this message belongs to. This value can be temporarily `nil` for messages that are being removed from
    /// the local cache, or when the local cache is in the process of invalidating.
    public let cid: ChannelId?

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
    public let extraData: [String: RawJSON]

    /// Quoted message.
    ///
    /// If message is inline reply this property will contain the message quoted by this reply.
    ///
    public var quotedMessage: ChatMessage? { _quotedMessage }
    @CoreDataLazy(forceLazy: true) internal var _quotedMessage: ChatMessage?

    /// A flag indicating whether the message was bounced due to moderation.
    public let isBounced: Bool

    /// A flag indicating whether the message is a silent message.
    ///
    /// Silent messages are special messages that don't increase the unread messages count nor mark a channel as unread.
    ///
    public let isSilent: Bool

    /// A flag indicating whether the message is a shadowed message.
    ///
    /// Shadowed message are special messages that are sent from shadow banned users.
    ///
    public let isShadowed: Bool

    /// The reactions to the message created by any user.
    public let reactionScores: [MessageReactionType: Int]

    /// The number of reactions per reaction type.
    public let reactionCounts: [MessageReactionType: Int]

    /// The user which is the author of the message.
    ///
    /// - Important: The `author` property is loaded and evaluated lazily to maintain high performance.
    public var author: ChatUser { _author }

    @CoreDataLazy internal var _author: ChatUser

    /// A list of users that are mentioned in this message.
    ///
    /// - Important: The `mentionedUsers` property is loaded and evaluated lazily to maintain high performance.
    public var mentionedUsers: Set<ChatUser> { _mentionedUsers }

    @CoreDataLazy internal var _mentionedUsers: Set<ChatUser>

    /// A list of users that participated in this message thread.
    /// The last user in the list is the author of the most recent reply.
    public var threadParticipants: [ChatUser] { _threadParticipants }

    @CoreDataLazy internal var _threadParticipants: [ChatUser]

    @CoreDataLazy internal var _attachments: [AnyChatMessageAttachment]

    /// The overall attachment count by attachment type.
    public var attachmentCounts: [AttachmentType: Int] {
        _attachments.reduce(into: [:]) { counts, attachment in
            counts[attachment.type] = (counts[attachment.type] ?? 0) + 1
        }
    }

    /// A list of latest 25 replies to this message.
    ///
    /// - Important: The `latestReplies` property is loaded and evaluated lazily to maintain high performance.
    public var latestReplies: [ChatMessage] { _latestReplies }
    // stream:annotation "Move to async"
    @CoreDataLazy(forceLazy: true) internal var _latestReplies: [ChatMessage]

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
    public var latestReactions: Set<ChatMessageReaction> { _latestReactions }

    @CoreDataLazy internal var _latestReactions: Set<ChatMessageReaction>

    /// The entire list of reactions to the message left by the current user.
    ///
    /// - Important: The `currentUserReactions` property is loaded and evaluated lazily to maintain high performance.
    public var currentUserReactions: Set<ChatMessageReaction> { _currentUserReactions }

    @CoreDataLazy internal var _currentUserReactions: Set<ChatMessageReaction>

    /// `true` if the author of the message is the currently logged-in user.
    public let isSentByCurrentUser: Bool

    /// The message pinning information. Is `nil` if the message is not pinned.
    public let pinDetails: MessagePinDetails?

    /// Internationalization and localization for the message. Only available for translated messages.
    public let translations: [TranslationLanguage: String]?

    /// If the message is authored by the current user this field contains the list of channel members
    /// who read this message (excluding the current user).
    ///
    /// - Note: For the message authored by other members this field is always empty.
    /// - Important: The `readBy` loads and evaluates user models. If you're interested only in `count`,
    /// it's recommended to use `readByCount` instead of `readBy.count` for better performance.
    public var readBy: Set<ChatUser> { _readBy }

    @CoreDataLazy(forceLazy: true) internal var _readBy: Set<ChatUser>

    /// For the message authored by the current user this field contains number of channel members
    /// who has read this message (excluding the current user).
    ///
    /// - Note: For the message authored by other channel members this field always returns `0`.
    public var readByCount: Int { readBy.count }

    @CoreDataLazy(forceLazy: true) internal var _readByCount: Int

    internal init(
        id: MessageId,
        cid: ChannelId,
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
        extraData: [String: RawJSON],
        quotedMessage: @escaping () -> ChatMessage?,
        isBounced: Bool,
        isSilent: Bool,
        isShadowed: Bool,
        reactionScores: [MessageReactionType: Int],
        reactionCounts: [MessageReactionType: Int],
        author: @escaping () -> ChatUser,
        mentionedUsers: @escaping () -> Set<ChatUser>,
        threadParticipants: @escaping () -> [ChatUser],
        attachments: @escaping () -> [AnyChatMessageAttachment],
        latestReplies: @escaping () -> [ChatMessage],
        localState: LocalMessageState?,
        isFlaggedByCurrentUser: Bool,
        latestReactions: @escaping () -> Set<ChatMessageReaction>,
        currentUserReactions: @escaping () -> Set<ChatMessageReaction>,
        isSentByCurrentUser: Bool,
        pinDetails: MessagePinDetails?,
        translations: [TranslationLanguage: String]?,
        readBy: @escaping () -> Set<ChatUser>,
        readByCount: @escaping () -> Int,
        underlyingContext: NSManagedObjectContext?
    ) {
        self.id = id
        self.cid = cid
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
        self.isBounced = isBounced
        self.isSilent = isSilent
        self.isShadowed = isShadowed
        self.reactionScores = reactionScores
        self.reactionCounts = reactionCounts
        self.localState = localState
        self.isFlaggedByCurrentUser = isFlaggedByCurrentUser
        self.isSentByCurrentUser = isSentByCurrentUser
        self.pinDetails = pinDetails
        self.translations = translations

        $_author = (author, underlyingContext)
        $_mentionedUsers = (mentionedUsers, underlyingContext)
        $_threadParticipants = (threadParticipants, underlyingContext)
        $_attachments = (attachments, underlyingContext)
        $_latestReplies = (latestReplies, underlyingContext)
        $_latestReactions = (latestReactions, underlyingContext)
        $_currentUserReactions = (currentUserReactions, underlyingContext)
        $_quotedMessage = (quotedMessage, underlyingContext)
        $_readBy = (readBy, underlyingContext)
        $_readByCount = (readByCount, underlyingContext)
    }
}

public extension ChatMessage {
    /// Indicates whether the message is pinned or not.
    var isPinned: Bool {
        pinDetails != nil
    }

    /// The total number of reactions.
    var totalReactionsCount: Int {
        reactionCounts.values.reduce(0, +)
    }

    /// Returns all the attachments with the payload type-erased.
    var allAttachments: [AnyChatMessageAttachment] {
        _attachments
    }

    /// Returns all the attachments with the payload of the provided type.
    ///
    /// - Important: Attachments are loaded lazily and cached to maintain high performance.
    func attachments<Payload: AttachmentPayload>(
        payloadType: Payload.Type
    ) -> [ChatMessageAttachment<Payload>] {
        _attachments.compactMap {
            $0.attachment(payloadType: payloadType)
        }
    }

    /// Returns the attachments of `.image` type.
    ///
    /// - Important: The `imageAttachments` are loaded lazily and cached to maintain high performance.
    var imageAttachments: [ChatMessageImageAttachment] {
        attachments(payloadType: ImageAttachmentPayload.self)
    }

    /// Returns the attachments of `.file` type.
    ///
    /// - Important: The `fileAttachments` are loaded lazily and cached to maintain high performance.
    var fileAttachments: [ChatMessageFileAttachment] {
        attachments(payloadType: FileAttachmentPayload.self)
    }

    /// Returns the attachments of `.video` type.
    ///
    /// - Important: The `videoAttachments` are loaded lazily and cached to maintain high performance.
    var videoAttachments: [ChatMessageVideoAttachment] {
        attachments(payloadType: VideoAttachmentPayload.self)
    }

    /// Returns the attachments of `.giphy` type.
    ///
    /// - Important: The `giphyAttachments` are loaded lazily and cached to maintain high performance.
    var giphyAttachments: [ChatMessageGiphyAttachment] {
        attachments(payloadType: GiphyAttachmentPayload.self)
    }

    /// Returns the attachments of `.linkPreview` type.
    ///
    /// - Important: The `linkAttachments` are loaded lazily and cached to maintain high performance.
    var linkAttachments: [ChatMessageLinkAttachment] {
        attachments(payloadType: LinkAttachmentPayload.self)
    }

    /// Returns the attachments of `.audio` type.
    ///
    /// - Important: The `audioAttachments` are loaded lazily and cached to maintain high performance.
    var audioAttachments: [ChatMessageAudioAttachment] {
        attachments(payloadType: AudioAttachmentPayload.self)
    }

    /// Returns attachment for the given identifier.
    /// - Parameter id: Attachment identifier.
    /// - Returns: A type-erased attachment.
    func attachment(with id: AttachmentId) -> AnyChatMessageAttachment? {
        _attachments.first { $0.id == id }
    }

    /// The message delivery status.
    /// Always returns `nil` when the message is authored by another user.
    /// Always returns `nil` when the message is `system/error/ephemeral/deleted`.
    var deliveryStatus: MessageDeliveryStatus? {
        guard isSentByCurrentUser else {
            // Delivery status exists only for messages sent by the current user.
            return nil
        }

        guard type == .regular || type == .reply else {
            // Delivery status only makes sense for regular messages and thread replies.
            return nil
        }

        switch localState {
        case .pendingSend, .sending, .pendingSync, .syncing, .deleting:
            return .pending
        case .sendingFailed, .syncingFailed, .deletingFailed:
            return .failed
        case nil:
            return readByCount > 0 ? .read : .sent
        }
    }

    var isLocalOnly: Bool {
        if let localState = self.localState {
            return localState.isWaitingToBeSentToServer
        }
        
        return type == .ephemeral || type == .error
    }
}

extension ChatMessage: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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
public struct MessagePinDetails {
    /// Date when the message got pinned
    public let pinnedAt: Date

    /// The user that pinned the message
    public let pinnedBy: ChatUser

    /// Date when the message pin expires. An nil value means that message does not expire
    public let expiresAt: Date?
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

    var isWaitingToBeSentToServer: Bool {
        switch self {
        case .pendingSync, .syncing, .syncingFailed, .pendingSend, .sending, .sendingFailed:
            return true
        case .deleting, .deletingFailed:
            return false
        }
    }
}

public enum LocalReactionState: String {
    ///  The reaction state is unknown
    case unknown = ""

    /// The reaction is waiting to be sent to the server
    case pendingSend

    /// The reaction is being sent
    case sending

    /// Creating the reaction failed and cannot be fulfilled
    case sendingFailed

    /// The reaction is waiting to be deleted from the server
    case pendingDelete

    /// The reaction is being deleted
    case deleting

    /// Deleting of the reaction failed and cannot be fulfilled
    case deletingFailed
}

/// The type describing message delivery status.
public struct MessageDeliveryStatus: RawRepresentable, Hashable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// The message delivery state for message that is being sent/edited/deleted.
    public static let pending = Self(rawValue: "pending")

    /// The message delivery state for message that is successfully sent.
    public static let sent = Self(rawValue: "sent")

    /// The message delivery state for message that is successfully sent and read by at least one channel member.
    public static let read = Self(rawValue: "read")

    /// The message delivery state for message failed to be sent/edited/deleted.
    public static let failed = Self(rawValue: "failed")
}
