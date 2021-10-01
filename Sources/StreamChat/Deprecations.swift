//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// - NOTE: Deprecations of the next major release.

public extension UserPresenceChangedEvent {
    @available(*, deprecated, message: "`user: ChatUser` is now accessible. Please, switch to `user.id`")
    var userId: UserId { user.id }
}

public extension UserUpdatedEvent {
    @available(*, deprecated, message: "`user: ChatUser` is now accessible. Please, switch to `user.id`")
    var userId: UserId { user.id }
}

public extension UserWatchingEvent {
    @available(*, deprecated, message: "`user: ChatUser` is now accessible. Please, switch to `user.id`")
    var userId: UserId { user.id }
}

public extension UserBannedEvent {
    @available(*, deprecated, message: "`user: ChatUser` is now accessible. Please, switch to `user.id`")
    var userId: UserId { user.id }
}

public extension UserUnbannedEvent {
    @available(*, deprecated, message: "`user: ChatUser` is now accessible. Please, switch to `user.id`")
    var userId: UserId { user.id }
}

public extension ChannelHiddenEvent {
    @available(*, deprecated, message: "Please, switch to `createdAt`")
    var hiddenAt: Date { createdAt }
}

public extension ChannelDeletedEvent {
    @available(*, deprecated, message: "Please, switch to `createdAt`")
    var deletedAt: Date { channel.deletedAt ?? createdAt }
}

public extension MemberAddedEvent {
    @available(*, deprecated, message: "`member: ChatChannelMember` is now accessible. Please, switch to `member.id`")
    var memberUserId: UserId { member.id }
}

public extension MemberUpdatedEvent {
    @available(*, deprecated, message: "`member: ChatChannelMember` is now accessible. Please, switch to `member.id`")
    var memberUserId: UserId { member.id }
}

public extension MemberRemovedEvent {
    @available(*, deprecated, message: "`user: ChatUser` is now accessible. Please, switch to `user.id`")
    var memberUserId: UserId { user.id }
}

public extension MessageNewEvent {
    @available(*, deprecated, message: "`user: ChatUser` is now accessible. Please, switch to `user.id`")
    var userId: UserId { user.id }
    
    @available(*, deprecated, message: "`message: ChatMessage` is now accessible. Please, switch to `message.id`")
    var messageId: UserId { message.id }
}

public extension MessageUpdatedEvent {
    @available(*, deprecated, message: "`user: ChatUser` is now accessible. Please, switch to `user.id`")
    var userId: UserId { user.id }
    
    @available(*, deprecated, message: "`message: ChatMessage` is now accessible. Please, switch to `message.id`")
    var messageId: UserId { message.id }
    
    @available(*, deprecated, message: "Use message.updatedAt")
    var updatedAt: Date { message.updatedAt }
}

public extension MessageDeletedEvent {
    @available(*, deprecated, message: "`user: ChatUser` is now accessible. Please, switch to `user?.id`")
    var userId: UserId {
        guard let user = user else {
            log.warning("The `message.deleted` event is triggered server-side and has no `user`. Empty `userId` will be returned.")
            return ""
        }
        
        return user.id
    }
    
    @available(*, deprecated, message: "`message: ChatMessage` is now accessible. Please, switch to `message.id`")
    var messageId: UserId { message.id }
    
    @available(*, deprecated, message: "Use message.deletedAt")
    var deletedAt: Date { message.deletedAt ?? createdAt }
}

public extension MessageReadEvent {
    @available(*, deprecated, message: "`user: ChatUser` is now accessible. Please, switch to `user.id`")
    var userId: UserId { user.id }
    
    @available(*, deprecated, message: "Please, switch to `createdAt`")
    var readAt: Date { createdAt }
}

public extension NotificationMessageNewEvent {
    @available(*, deprecated, message: "`message: ChatMessage` is now accessible. Please, switch to `message.author.id`")
    var userId: UserId { message.author.id }
    
    @available(*, deprecated, message: "`message: ChatMessage` is now accessible. Please, switch to `message.id`")
    var messageId: MessageId { message.id }
}

public extension NotificationMarkAllReadEvent {
    @available(*, deprecated, message: "`user: ChatUser` is now accessible. Please, switch to `user.id`")
    var userId: UserId { user.id }
    
    @available(*, deprecated, message: "Please, switch to `createdAt`")
    var readAt: Date { createdAt }
}

public extension NotificationMarkReadEvent {
    @available(*, deprecated, message: "`user: ChatUser` is now accessible. Please, switch to `user.id`")
    var userId: UserId { user.id }
    
    @available(*, deprecated, message: "Please, switch to `createdAt`")
    var readAt: Date { createdAt }
}

public extension NotificationMutesUpdatedEvent {
    @available(*, deprecated, message: "`user: CurrentChatUser` is now accessible. Please, switch to `currentUser.id`")
    var currentUserId: UserId { currentUser.id }
}

public extension NotificationRemovedFromChannelEvent {
    @available(*, deprecated, message: "`user: ChatUser` is now accessible. Please, switch to `user.id`")
    var currentUserId: UserId { user.id }
}

public extension NotificationChannelMutesUpdatedEvent {
    @available(*, deprecated, message: "`user: CurrentChatUser` is now accessible. Please, switch to `currentUser.id`")
    var userId: UserId { currentUser.id }
}

public extension NotificationInvitedEvent {
    @available(*, deprecated, message: "`member: ChatChannelMember` is now accessible. Please, switch to `member.id`")
    var memberUserId: UserId { member.id }
}

public extension NotificationInviteAcceptedEvent {
    @available(*, deprecated, message: "`member: ChatChannelMember` is now accessible. Please, switch to `member.id`")
    var memberUserId: UserId { member.id }
}

public extension NotificationInviteRejectedEvent {
    @available(*, deprecated, message: "`member: ChatChannelMember` is now accessible. Please, switch to `member.id`")
    var memberUserId: UserId { member.id }
}

public extension ReactionNewEvent {
    @available(*, deprecated, message: "`user: ChatUser` is now accessible. Please, switch to `user.id`")
    var userId: UserId { user.id }
    
    @available(*, deprecated, message: "`message: ChatMessage` is now accessible. Please, switch to `message.id`")
    var messageId: UserId { message.id }

    @available(*, deprecated, message: "`reaction: ChatMessageReaction` is now accessible. Please, switch to `reaction.type`")
    var reactionType: MessageReactionType { reaction.type }
    
    @available(*, deprecated, message: "`reaction: ChatMessageReaction` is now accessible. Please, switch to `reaction.score`")
    var reactionScore: Int { reaction.score }
}

public extension ReactionUpdatedEvent {
    @available(*, deprecated, message: "`user: ChatUser` is now accessible. Please, switch to `user.id`")
    var userId: UserId { user.id }
    
    @available(*, deprecated, message: "`message: ChatMessage` is now accessible. Please, switch to `message.id`")
    var messageId: UserId { message.id }

    @available(*, deprecated, message: "`reaction: ChatMessageReaction` is now accessible. Please, switch to `reaction.type`")
    var reactionType: MessageReactionType { reaction.type }
    
    @available(*, deprecated, message: "`reaction: ChatMessageReaction` is now accessible. Please, switch to `reaction.score`")
    var reactionScore: Int { reaction.score }
    
    @available(*, deprecated, message: "`reaction: ChatMessageReaction` is now accessible. Please, switch to `reaction.updatedAt`")
    var updatedAt: Date { reaction.updatedAt }
}

public extension ReactionDeletedEvent {
    @available(*, deprecated, message: "`user: ChatUser` is now accessible. Please, switch to `user.id`")
    var userId: UserId { user.id }
    
    @available(*, deprecated, message: "`message: ChatMessage` is now accessible. Please, switch to `message.id`")
    var messageId: UserId { message.id }

    @available(*, deprecated, message: "`reaction: ChatMessageReaction` is now accessible. Please, switch to `reaction.type`")
    var reactionType: MessageReactionType { reaction.type }
    
    @available(*, deprecated, message: "`reaction: ChatMessageReaction` is now accessible. Please, switch to `reaction.score`")
    var reactionScore: Int { reaction.score }
}

public extension TypingEvent {
    @available(*, deprecated, message: "`user: ChatUser` is now accessible. Please, switch to `user.id`")
    var userId: UserId { user.id }
}

@available(*, deprecated, renamed: "NotificationInviteRejectedEvent")
public typealias NotificationInviteRejected = NotificationInviteRejectedEvent

@available(*, deprecated, renamed: "NotificationInviteAcceptedEvent")
public typealias NotificationInviteAccepted = NotificationInviteAcceptedEvent
