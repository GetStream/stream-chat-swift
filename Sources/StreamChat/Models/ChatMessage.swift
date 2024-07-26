//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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

    /// A date when the message was updated last time. This includes any action to the message, like reactions.
    public let updatedAt: Date

    /// If the message was deleted, this variable contains a timestamp of that event, otherwise `nil`.
    public let deletedAt: Date?

    /// The date when the message text, and only the text, was edited. `Nil` if it was not edited.
    public let textUpdatedAt: Date?

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
    public var quotedMessage: ChatMessage? { _quotedMessage() }
    let _quotedMessage: () -> ChatMessage?

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

    /// The reaction information grouped by type. Only available if reactions v2 is supported.
    public let reactionGroups: [MessageReactionType: ChatMessageReactionGroup]

    /// The user which is the author of the message.
    public let author: ChatUser

    /// A list of users that are mentioned in this message.
    public let mentionedUsers: Set<ChatUser>

    /// A list of users that participated in this message thread.
    /// The last user in the list is the author of the most recent reply.
    public let threadParticipants: [ChatUser]

    public var threadParticipantsCount: Int { threadParticipants.count }

    let _attachments: [AnyChatMessageAttachment]

    /// The overall attachment count by attachment type.
    public var attachmentCounts: [AttachmentType: Int] {
        _attachments.reduce(into: [:]) { counts, attachment in
            counts[attachment.type] = (counts[attachment.type] ?? 0) + 1
        }
    }

    /// A list of latest 25 replies to this message.
    public let latestReplies: [ChatMessage]

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
    public let latestReactions: Set<ChatMessageReaction>

    /// The entire list of reactions to the message left by the current user.
    public let currentUserReactions: Set<ChatMessageReaction>

    public var currentUserReactionsCount: Int { currentUserReactions.count }

    /// `true` if the author of the message is the currently logged-in user.
    public let isSentByCurrentUser: Bool

    /// The message pinning information. Is `nil` if the message is not pinned.
    public let pinDetails: MessagePinDetails?

    /// The available automatic translations for this message.
    public let translations: [TranslationLanguage: String]?

    /// Gets the translated text given the desired language in case the translation is valid.
    public func translatedText(for language: TranslationLanguage) -> String? {
        guard let translatedText = translations?[language] else { return nil }
        guard translatedText != text else { return nil }
        guard language != originalLanguage else { return nil }
        guard !text.isEmpty else { return nil }
        guard command == nil else { return nil }
        return translatedText
    }

    /// The original language of the message.
    public let originalLanguage: TranslationLanguage?
  
    /// The moderation details in case the message was moderated.
    public let moderationDetails: MessageModerationDetails?

    /// If the message is authored by the current user this field contains the list of channel members
    /// who read this message (excluding the current user).
    ///
    /// - Note: For the message authored by other members this field is always empty.
    public let readBy: Set<ChatUser>

    /// For the message authored by the current user this field contains number of channel members
    /// who has read this message (excluding the current user).
    ///
    /// - Note: For the message authored by other channel members this field always returns `0`.
    public var readByCount: Int { readBy.count }
    
    /// Optional poll that is part of the message.
    public let poll: Poll?

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
        quotedMessage: ChatMessage?,
        isBounced: Bool,
        isSilent: Bool,
        isShadowed: Bool,
        reactionScores: [MessageReactionType: Int],
        reactionCounts: [MessageReactionType: Int],
        reactionGroups: [MessageReactionType: ChatMessageReactionGroup],
        author: ChatUser,
        mentionedUsers: Set<ChatUser>,
        threadParticipants: [ChatUser],
        attachments: [AnyChatMessageAttachment],
        latestReplies: [ChatMessage],
        localState: LocalMessageState?,
        isFlaggedByCurrentUser: Bool,
        latestReactions: Set<ChatMessageReaction>,
        currentUserReactions: Set<ChatMessageReaction>,
        isSentByCurrentUser: Bool,
        pinDetails: MessagePinDetails?,
        translations: [TranslationLanguage: String]?,
        originalLanguage: TranslationLanguage?,
        moderationDetails: MessageModerationDetails?,
        readBy: Set<ChatUser>,
        poll: Poll?,
        textUpdatedAt: Date?
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
        self.reactionGroups = reactionGroups
        self.localState = localState
        self.isFlaggedByCurrentUser = isFlaggedByCurrentUser
        self.isSentByCurrentUser = isSentByCurrentUser
        self.pinDetails = pinDetails
        self.translations = translations
        self.originalLanguage = originalLanguage
        self.moderationDetails = moderationDetails
        self.textUpdatedAt = textUpdatedAt
        self.poll = poll

        self.author = author
        self.mentionedUsers = mentionedUsers
        self.threadParticipants = threadParticipants
        self.latestReplies = latestReplies
        self.latestReactions = latestReactions
        self.currentUserReactions = currentUserReactions
        self.readBy = readBy
        _attachments = attachments
        _quotedMessage = { quotedMessage }
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
    func attachments<Payload: AttachmentPayload>(
        payloadType: Payload.Type
    ) -> [ChatMessageAttachment<Payload>] {
        _attachments.compactMap {
            $0.attachment(payloadType: payloadType)
        }
    }

    /// Returns the attachments of `.image` type.
    var imageAttachments: [ChatMessageImageAttachment] {
        attachments(payloadType: ImageAttachmentPayload.self)
    }

    /// Returns the attachments of `.file` type.
    var fileAttachments: [ChatMessageFileAttachment] {
        attachments(payloadType: FileAttachmentPayload.self)
    }

    /// Returns the attachments of `.video` type.
    var videoAttachments: [ChatMessageVideoAttachment] {
        attachments(payloadType: VideoAttachmentPayload.self)
    }

    /// Returns the attachments of `.giphy` type.
    var giphyAttachments: [ChatMessageGiphyAttachment] {
        attachments(payloadType: GiphyAttachmentPayload.self)
    }

    /// Returns the attachments of `.linkPreview` type.
    var linkAttachments: [ChatMessageLinkAttachment] {
        attachments(payloadType: LinkAttachmentPayload.self)
    }

    /// Returns the attachments of `.audio` type.
    var audioAttachments: [ChatMessageAudioAttachment] {
        attachments(payloadType: AudioAttachmentPayload.self)
    }

    /// Returns the attachments of `.voiceRecording` type.
    var voiceRecordingAttachments: [ChatMessageVoiceRecordingAttachment] {
        attachments(payloadType: VoiceRecordingAttachmentPayload.self)
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
            return localState.isLocalOnly
        }
        
        return type == .ephemeral || type == .error
    }
}

extension ChatMessage: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.id == rhs.id else { return false }
        guard lhs.localState == rhs.localState else { return false }
        guard lhs.updatedAt == rhs.updatedAt else { return false }
        guard lhs.allAttachments == rhs.allAttachments else { return false }
        guard lhs.author == rhs.author else { return false }
        guard lhs.currentUserReactionsCount == rhs.currentUserReactionsCount else { return false }
        guard lhs.text == rhs.text else { return false }
        guard lhs.parentMessageId == rhs.parentMessageId else { return false }
        guard lhs.reactionCounts == rhs.reactionCounts else { return false }
        guard lhs.reactionGroups == rhs.reactionGroups else { return false }
        guard lhs.reactionScores == rhs.reactionScores else { return false }
        guard lhs.readByCount == rhs.readByCount else { return false }
        guard lhs.replyCount == rhs.replyCount else { return false }
        guard lhs.showReplyInChannel == rhs.showReplyInChannel else { return false }
        guard lhs.threadParticipantsCount == rhs.threadParticipantsCount else { return false }
        guard lhs.arguments == rhs.arguments else { return false }
        guard lhs.command == rhs.command else { return false }
        guard lhs.extraData == rhs.extraData else { return false }
        guard lhs.isFlaggedByCurrentUser == rhs.isFlaggedByCurrentUser else { return false }
        guard lhs.isShadowed == rhs.isShadowed else { return false }
        guard lhs.quotedMessage == rhs.quotedMessage else { return false }
        guard lhs.translations == rhs.translations else { return false }
        guard lhs.type == rhs.type else { return false }
        return true
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

    /// If the message is available only locally. The message is not on the server.
    var isLocalOnly: Bool {
        self == .pendingSend || self == .sendingFailed || self == .sending
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
