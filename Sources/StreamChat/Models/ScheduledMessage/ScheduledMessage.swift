//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A message the server sends to a channel at `scheduledAt`.
///
/// Until it is sent, the current user can edit, reschedule, send now or delete it. Other channel members
/// see nothing until it is sent, and then it arrives as a regular message.
public final class ScheduledMessage: Identifiable, Equatable, @unchecked Sendable {
    /// The unique identifier of the scheduled message.
    ///
    /// It is also the identifier of `message`, and not necessarily the one of the message created when it is sent.
    public let id: String

    /// The channel the message is sent to.
    public let cid: ChannelId

    /// A summary of the channel the message is sent to.
    public let channel: ScheduledMessageChannel

    /// The message that will be sent, so it can be rendered like any other message.
    ///
    /// It is authored by the current user, and its `createdAt` is `scheduledAt`. It is not in the messages of the channel
    /// until it is sent, and has no reactions, replies or read state. The server returns only the ids of the mentioned
    /// users, the quoted message and the poll, so they are filled in from the ones saved locally.
    public let message: ChatMessage

    /// The identifier of the message quoted by `message`, even when the quoted message is not available locally.
    public let quotedMessageId: MessageId?

    /// The date when the message is sent.
    public let scheduledAt: Date

    /// The current status of the scheduled message.
    public let status: ScheduledMessageStatus

    /// The problem of the scheduled message, telling whether the server or the local device failed.
    ///
    /// When the latest local changes failed, their error is reported even if the server also failed to publish
    /// the message, and the publishing failure is reported again once the changes are resolved.
    public let error: ScheduledMessageError?

    /// The date when the message was scheduled.
    public let createdAt: Date

    /// The date when the message was last edited or rescheduled.
    public let updatedAt: Date

    /// Whether the message is still waiting to be sent, which is the case unless it failed.
    public var isPending: Bool {
        status != .failed
    }

    /// The state of the local changes that are not on the server yet.
    ///
    /// A scheduled message is saved locally first, then sent to the server once its attachments are uploaded.
    /// It is `nil` when the server has the latest changes.
    public var syncState: ScheduledMessageSyncState? {
        ScheduledMessageSyncState(message.localState)
    }

    /// Whether the server has the scheduled message, which is needed to send it now.
    ///
    /// It is `false` until the message is scheduled on the server for the first time.
    public var isOnServer: Bool {
        switch message.localState {
        case .pendingSend, .sending, .sendingFailed:
            return false
        default:
            return true
        }
    }

    init(
        id: String,
        cid: ChannelId,
        channel: ScheduledMessageChannel,
        message: ChatMessage,
        quotedMessageId: MessageId?,
        scheduledAt: Date,
        status: ScheduledMessageStatus,
        error: ScheduledMessageError? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.cid = cid
        self.channel = channel
        self.message = message
        self.quotedMessageId = quotedMessageId
        self.scheduledAt = scheduledAt
        self.status = status
        self.error = error
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public static func == (lhs: ScheduledMessage, rhs: ScheduledMessage) -> Bool {
        lhs.id == rhs.id
            && lhs.cid == rhs.cid
            && lhs.channel == rhs.channel
            && lhs.message.text == rhs.message.text
            && lhs.message.allAttachments == rhs.message.allAttachments
            && lhs.message.mentionedUsers.map(\.id).sorted() == rhs.message.mentionedUsers.map(\.id).sorted()
            && lhs.quotedMessageId == rhs.quotedMessageId
            && lhs.message.parentMessageId == rhs.message.parentMessageId
            && lhs.message.showReplyInChannel == rhs.message.showReplyInChannel
            && lhs.message.extraData == rhs.message.extraData
            && lhs.message.mentionedHere == rhs.message.mentionedHere
            && lhs.message.mentionedChannel == rhs.message.mentionedChannel
            && lhs.message.mentionedRoles == rhs.message.mentionedRoles
            && lhs.message.isSilent == rhs.message.isSilent
            && lhs.message.pinDetails?.expiresAt == rhs.message.pinDetails?.expiresAt
            && (lhs.message.pinDetails == nil) == (rhs.message.pinDetails == nil)
            && lhs.message.poll?.id == rhs.message.poll?.id
            && lhs.scheduledAt == rhs.scheduledAt
            && lhs.status == rhs.status
            && lhs.createdAt == rhs.createdAt
            && lhs.updatedAt == rhs.updatedAt
            && lhs.message.localState == rhs.message.localState
            && lhs.error == rhs.error
    }
}
