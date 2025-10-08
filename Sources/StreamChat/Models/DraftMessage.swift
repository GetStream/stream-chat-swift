//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public struct DraftMessage {
    /// A unique identifier of the message.
    public let id: MessageId

    /// The ChannelId this message belongs to.
    public let cid: ChannelId?

    /// The ID of the parent message, if the message is a reply.
    public let threadId: MessageId?

    /// The text of the message.
    public let text: String

    /// A flag indicating whether the message is a silent message.
    ///
    /// Silent messages are special messages that don't increase the unread messages count nor mark a channel as unread.
    public let isSilent: Bool

    /// If the message was created by a specific `/` command, the command is saved in this variable.
    public let command: String?

    /// The date when the draft was created.
    public let createdAt: Date

    /// If the message was created by a specific `/` command, the arguments of the command are stored in this variable.
    public let arguments: String?

    /// If the message is a reply and this flag is `true`, the message should be also shown in the channel, not only in the
    /// reply thread.
    public let showReplyInChannel: Bool

    /// Additional data associated with the message.
    public let extraData: [String: RawJSON]

    /// Quoted message.
    ///
    /// If message is inline reply this property will contain the message quoted by this reply.
    public var quotedMessage: ChatMessage? { _quotedMessage() }
    let _quotedMessage: () -> ChatMessage?

    /// A list of users that are mentioned in this message.
    public let mentionedUsers: Set<ChatUser>

    /// A list of attachments of the message.
    public let attachments: [AnyChatMessageAttachment]

    /// This property is used to make it easier to convert to a regular message.
    internal let currentUser: ChatUser

    init(
        id: MessageId,
        cid: ChannelId?,
        threadId: MessageId?,
        text: String,
        isSilent: Bool,
        command: String?,
        createdAt: Date,
        arguments: String?,
        showReplyInChannel: Bool,
        extraData: [String: RawJSON],
        currentUser: ChatUser,
        quotedMessage: @escaping () -> ChatMessage?,
        mentionedUsers: Set<ChatUser>,
        attachments: [AnyChatMessageAttachment]
    ) {
        self.id = id
        self.cid = cid
        self.threadId = threadId
        self.text = text
        self.isSilent = isSilent
        self.command = command
        self.createdAt = createdAt
        self.arguments = arguments
        self.showReplyInChannel = showReplyInChannel
        self.extraData = extraData
        _quotedMessage = quotedMessage
        self.mentionedUsers = mentionedUsers
        self.attachments = attachments
        self.currentUser = currentUser
    }

    init(_ message: ChatMessage) {
        id = message.id
        cid = message.cid
        text = message.text
        isSilent = message.isSilent
        command = message.command
        createdAt = message.createdAt
        arguments = message.arguments
        threadId = message.parentMessageId
        showReplyInChannel = message.showReplyInChannel
        extraData = message.extraData
        _quotedMessage = { message.quotedMessage }
        mentionedUsers = message.mentionedUsers
        attachments = message.allAttachments
        currentUser = message.author
    }
}

extension DraftMessage: Equatable {
    public static func == (lhs: DraftMessage, rhs: DraftMessage) -> Bool {
        lhs.text == rhs.text
            && lhs.id == rhs.id
            && lhs.cid == rhs.cid
            && lhs.isSilent == rhs.isSilent
            && lhs.command == rhs.command
            && lhs.createdAt == rhs.createdAt
            && lhs.createdAt.timeIntervalSince1970 == rhs.createdAt.timeIntervalSince1970
            && lhs.arguments == rhs.arguments
            && lhs.threadId == rhs.threadId
            && lhs.quotedMessage == rhs.quotedMessage
            && lhs.attachments == rhs.attachments
    }
}

extension ChatMessage {
    /// Converts the draft message to a regular message so that it
    /// can be easily used in existing UI components.
    public init(_ draft: DraftMessage) {
        id = draft.id
        cid = draft.cid
        text = draft.text
        type = .regular
        command = draft.command
        createdAt = draft.createdAt
        locallyCreatedAt = draft.createdAt
        updatedAt = draft.createdAt
        deletedAt = nil
        arguments = draft.arguments
        parentMessageId = draft.threadId
        showReplyInChannel = draft.showReplyInChannel
        replyCount = 0
        extraData = draft.extraData
        _quotedMessage = { draft.quotedMessage }
        isBounced = false
        isSilent = false
        isShadowed = false
        reactionScores = [:]
        reactionCounts = [:]
        reactionGroups = [:]
        author = draft.currentUser
        mentionedUsers = draft.mentionedUsers
        threadParticipants = []
        _attachments = draft.attachments
        latestReplies = []
        localState = nil
        isFlaggedByCurrentUser = false
        latestReactions = []
        currentUserReactions = []
        isSentByCurrentUser = true
        pinDetails = nil
        translations = nil
        originalLanguage = nil
        moderationDetails = nil
        readBy = []
        poll = nil
        textUpdatedAt = nil
        draftReply = nil
        reminder = nil
        sharedLocation = nil
        channelRole = nil
        deletedForMe = false
    }
}
