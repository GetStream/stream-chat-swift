//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// Triggered when a new message is sent to channel.
public struct MessageNewEvent: ChannelSpecificEvent, HasUnreadCount {
    /// The user who sent a message.
    public let user: ChatUser

    /// The message that was sent.
    public let message: ChatMessage

    /// The channel identifier the message was sent to.
    public var cid: ChannelId { channel.cid }

    /// The channel a message was sent to.
    public let channel: ChatChannel

    /// The event timestamp.
    public let createdAt: Date

    /// The # of channel watchers.
    public let watcherCount: Int?

    /// The unread counts.
    public let unreadCount: UnreadCount?
}

class MessageNewEventDTO: EventDTO {
    let user: UserPayload
    let cid: ChannelId
    let message: MessagePayload
    let createdAt: Date
    let watcherCount: Int?
    let unreadCount: UnreadCountPayload?
    let payload: EventPayload

    init(from response: EventPayload) throws {
        user = try response.value(at: \.user)
        cid = try response.value(at: \.cid)
        message = try response.value(at: \.message)
        createdAt = try response.value(at: \.createdAt)
        watcherCount = try? response.value(at: \.watcherCount)
        unreadCount = try? response.value(at: \.unreadCount)
        payload = response
    }

    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard
            let userDTO = session.user(id: user.id),
            let messageDTO = session.message(id: message.id),
            let channelDTO = session.channel(cid: cid),
            let currentUser = session.currentUser
        else { return nil }

        return try? MessageNewEvent(
            user: userDTO.asModel(),
            message: messageDTO.asModel(),
            channel: channelDTO.asModel(),
            createdAt: createdAt,
            watcherCount: watcherCount,
            unreadCount: UnreadCount(currentUserDTO: currentUser)
        )
    }
}

/// Triggered when a message is updated.
public struct MessageUpdatedEvent: ChannelSpecificEvent {
    /// The use who updated the message.
    public let user: ChatUser

    /// The channel identifier the message is sent to.
    public var cid: ChannelId { channel.cid }

    /// The channel a message is sent to.
    public let channel: ChatChannel

    /// The updated message.
    public let message: ChatMessage

    /// The event timestamp.
    public let createdAt: Date
}

class MessageUpdatedEventDTO: EventDTO {
    let user: UserPayload
    let cid: ChannelId
    let message: MessagePayload
    let createdAt: Date
    let payload: EventPayload

    init(from response: EventPayload) throws {
        user = try response.value(at: \.user)
        cid = try response.value(at: \.cid)
        message = try response.value(at: \.message)
        createdAt = try response.value(at: \.createdAt)
        payload = response
    }

    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard
            let userDTO = session.user(id: user.id),
            let messageDTO = session.message(id: message.id),
            let channelDTO = session.channel(cid: cid)
        else { return nil }

        return try? MessageUpdatedEvent(
            user: userDTO.asModel(),
            channel: channelDTO.asModel(),
            message: messageDTO.asModel(),
            createdAt: createdAt
        )
    }
}

/// Triggered when a new message is deleted.
public struct MessageDeletedEvent: ChannelSpecificEvent {
    /// The user who deleted the message.
    public let user: ChatUser?

    /// The channel identifier a message was deleted from.
    public var cid: ChannelId { channel.cid }

    /// The channel a message was deleted from.
    public let channel: ChatChannel

    /// The deleted message.
    public let message: ChatMessage

    /// The event timestamp.
    public let createdAt: Date

    /// A Boolean value indicating whether it is an hard delete or not.
    public let isHardDelete: Bool
}

class MessageDeletedEventDTO: EventDTO {
    let user: UserPayload?
    let cid: ChannelId
    let message: MessagePayload
    let createdAt: Date
    let payload: EventPayload
    let hardDelete: Bool

    init(from response: EventPayload) throws {
        user = try? response.value(at: \.user)
        cid = try response.value(at: \.cid)
        message = try response.value(at: \.message)
        createdAt = try response.value(at: \.createdAt)
        payload = response
        hardDelete = response.hardDelete
    }

    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard let channelDTO = session.channel(cid: cid) else {
            return nil
        }

        let userDTO = user.flatMap { session.user(id: $0.id) }
        let messageDTO = session.message(id: message.id)

        // If the message is hard deleted, it is not available as DTO.
        // So we map the Payload Directly to the Model.
        let message = (try? messageDTO?.asModel()) ?? message.asModel(currentUser: session.currentUser)

        return try? MessageDeletedEvent(
            user: userDTO?.asModel(),
            channel: channelDTO.asModel(),
            message: message,
            createdAt: createdAt,
            isHardDelete: hardDelete
        )
    }
}

/// `ChannelReadEvent`, this event tells that User has mark read all messages in channel.
public typealias ChannelReadEvent = MessageReadEvent

/// `ChannelReadEvent`, this event tells that User has mark read all messages in channel.
public struct MessageReadEvent: ChannelSpecificEvent {
    /// The user who read the channel.
    public let user: ChatUser

    /// The identifier of the read channel.
    public var cid: ChannelId { channel.cid }

    /// The read channel.
    public let channel: ChatChannel

    /// The thread if a thread was read.
    public let thread: ChatThread?

    /// The event timestamp.
    public let createdAt: Date

    /// The unread counts of the current user.
    public let unreadCount: UnreadCount?
}

class MessageReadEventDTO: EventDTO {
    let user: UserPayload
    let cid: ChannelId
    let createdAt: Date
    let unreadCount: UnreadCountPayload?
    let payload: EventPayload

    init(from response: EventPayload) throws {
        user = try response.value(at: \.user)
        cid = try response.value(at: \.cid)
        createdAt = try response.value(at: \.createdAt)
        unreadCount = try? response.value(at: \.unreadCount)
        payload = response
    }

    func toDomainEvent(session: DatabaseSession) -> Event? {
        guard
            let userDTO = session.user(id: user.id),
            let channelDTO = session.channel(cid: cid),
            let currentUser = session.currentUser
        else { return nil }

        var threadDTO: ThreadDTO?
        if let threadId = payload.threadDetails?.value?.parentMessageId {
            threadDTO = session.thread(parentMessageId: threadId, cache: nil)
        }

        return try? MessageReadEvent(
            user: userDTO.asModel(),
            channel: channelDTO.asModel(),
            thread: threadDTO?.asModel(),
            createdAt: createdAt,
            unreadCount: UnreadCount(currentUserDTO: currentUser)
        )
    }
}

// Triggered when the current user creates a new message and is pending to be sent.
public struct NewMessagePendingEvent: Event {
    public var message: ChatMessage
}

// Triggered when a message failed being sent.
public struct NewMessageErrorEvent: Event {
    public let messageId: MessageId
    public let error: Error
}

// MARK: - Workaround to map a deleted message to Model.

// At the moment our SDK does not support mapping Payload -> Model
// So this is just a workaround for `MessageDeletedEvent` to have the `message` non-optional.
// So some of the data will be incorrect, but for this is use case is more than enough.

private extension MessagePayload {
    func asModel(currentUser: CurrentUserDTO?) -> ChatMessage {
        .init(
            id: id,
            cid: cid,
            text: text,
            type: type,
            command: command,
            createdAt: createdAt,
            locallyCreatedAt: nil,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            arguments: args,
            parentMessageId: parentId,
            showReplyInChannel: showReplyInChannel,
            replyCount: replyCount,
            extraData: extraData,
            quotedMessage: quotedMessage?.asModel(currentUser: currentUser),
            isBounced: false,
            isSilent: isSilent,
            isShadowed: isShadowed,
            reactionScores: reactionScores,
            reactionCounts: reactionCounts,
            reactionGroups: [:],
            author: user.asModel(),
            mentionedUsers: Set(mentionedUsers.map { $0.asModel() }),
            threadParticipants: threadParticipants.map { $0.asModel() },
            attachments: [],
            latestReplies: [],
            localState: nil,
            isFlaggedByCurrentUser: false,
            latestReactions: [],
            currentUserReactions: [],
            isSentByCurrentUser: user.id == currentUser?.user.id,
            pinDetails: nil,
            translations: nil,
            originalLanguage: originalLanguage.map { TranslationLanguage(languageCode: $0) },
            moderationDetails: nil,
            readBy: [],
            poll: nil,
            textUpdatedAt: messageTextUpdatedAt,
            draftReply: nil,
            reminder: nil,
            sharedLocation: nil
        )
    }
}

private extension UserPayload {
    func asModel() -> ChatUser {
        .init(
            id: id,
            name: name,
            imageURL: imageURL,
            isOnline: isOnline,
            isBanned: isBanned,
            isFlaggedByCurrentUser: false,
            userRole: role,
            teamsRole: teamsRole,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deactivatedAt: deactivatedAt,
            lastActiveAt: lastActiveAt,
            teams: Set(teams),
            language: language.map { TranslationLanguage(languageCode: $0) },
            avgResponseTime: avgResponseTime,
            extraData: extraData
        )
    }
}
