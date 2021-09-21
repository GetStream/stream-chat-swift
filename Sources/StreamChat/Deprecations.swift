//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// - NOTE: Deprecations of the next major release.

public extension UserPresenceChangedEvent {
    @available(*, deprecated, message: "Use user.id")
    var userId: UserId { user.id }
}

public extension UserUpdatedEvent {
    @available(*, deprecated, message: "Use user.id")
    var userId: UserId { user.id }
}

public extension UserWatchingEvent {
    @available(*, deprecated, message: "Use user.id")
    var userId: UserId { user.id }
}

public extension UserBannedEvent {
    @available(*, deprecated, message: "Use user.id")
    var userId: UserId { user.id }
}

public extension UserUnbannedEvent {
    @available(*, deprecated, message: "Use user.id")
    var userId: UserId { user.id }
}

public extension ChannelHiddenEvent {
    @available(*, deprecated, message: "Use createdAt")
    var hiddenAt: Date { createdAt }
}

public extension ChannelDeletedEvent {
    @available(*, deprecated, message: "Use channel.deletedAt")
    var deletedAt: Date { channel.deletedAt ?? createdAt }
}

public extension MessageNewEvent {
    @available(*, deprecated, message: "Use user.id")
    var userId: UserId { user.id }
    
    @available(*, deprecated, message: "Use message.id")
    var messageId: UserId { message.id }
}

public extension MessageUpdatedEvent {
    @available(*, deprecated, message: "Use user.id")
    var userId: UserId { user.id }
    
    @available(*, deprecated, message: "Use message.id")
    var messageId: UserId { message.id }
    
    @available(*, deprecated, message: "Use message.updatedAt")
    var updatedAt: Date { message.updatedAt }
}

public extension MessageDeletedEvent {
    @available(*, deprecated, message: "Use user.id")
    var userId: UserId { user.id }
    
    @available(*, deprecated, message: "Use message.id")
    var messageId: UserId { message.id }
    
    @available(*, deprecated, message: "Use message.deletedAt")
    var deletedAt: Date { message.deletedAt ?? createdAt }
}

public extension MessageReadEvent {
    @available(*, deprecated, message: "Use user.id")
    var userId: UserId { user.id }
    
    @available(*, deprecated, message: "Use createdAt")
    var readAt: Date { createdAt }
}

public extension TypingEvent {
    @available(*, deprecated, message: "Use user.id")
    var userId: UserId { user.id }
}
