//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// An `Event` object representing an event in the chat system.
public protocol Event {
    func user() -> ChatUser?
    func currentUser() -> CurrentChatUser?
    func channel() -> ChatChannel?
    func member() -> ChatChannelMember?
    func unreadCount() -> UnreadCount?
    func message() -> ChatMessage?
}

extension Event {
    public func user() -> ChatUser? {
        (self as? EventWithPayload)?.savedData?.user
    }
    
    public func currentUser() -> CurrentChatUser? {
        (self as? EventWithPayload)?.savedData?.currentUser
    }
    
    public func channel() -> ChatChannel? {
        (self as? EventWithPayload)?.savedData?.channel
    }
    
    public func member() -> ChatChannelMember? {
        (self as? EventWithPayload)?.savedData?.member
    }
    
    public func unreadCount() -> UnreadCount? {
        (self as? EventWithPayload)?.savedData?.unreadCount
    }
    
    public func message() -> ChatMessage? {
        if let eventWithPayload = self as? EventWithPayload {
            if let savedData = eventWithPayload.savedData {
                if let message = savedData.message {
                    return message
                } else {
                    print("### no message")
                    return nil
                }
            } else {
                print("### no savedData")
                return nil
            }
        } else {
            print("### not eventWithPayload")
            return nil
        }
    }
}

/// Helper object for accessing event data after it's saved to CoreData.
public class SavedEventData {
    @CoreDataLazy var user: ChatUser?
    @CoreDataLazy var currentUser: CurrentChatUser?
    @CoreDataLazy var channel: ChatChannel?
    @CoreDataLazy var member: ChatChannelMember?
    @CoreDataLazy var unreadCount: UnreadCount?
    @CoreDataLazy var message: ChatMessage?
    
    init(
        user: @escaping (() -> ChatUser?) = { nil },
        currentUser: @escaping (() -> CurrentChatUser?) = { nil },
        channel: @escaping (() -> ChatChannel?) = { nil },
        member: @escaping (() -> ChatChannelMember?) = { nil },
        unreadCount: @escaping (() -> UnreadCount?) = { nil },
        message: @escaping (() -> ChatMessage?) = { nil },
        underlyingContext: NSManagedObjectContext?
    ) {
        $user = (user, underlyingContext)
        $currentUser = (currentUser, underlyingContext)
        $channel = (channel, underlyingContext)
        $member = (member, underlyingContext)
        $unreadCount = (unreadCount, underlyingContext)
        $message = (message, underlyingContext)
    }
}

/// An internal protocol marking the Events carrying the payload. This payload can be then used for additional work,
/// i.e. for storing the data to the database.
protocol EventWithPayload: Event {
    /// Type-erased event payload. Cast it to `EventPayload` when you need to use it.
    var payload: Any { get }
    /// Actual, persisted event data
    var savedData: SavedEventData? { get set }
}

/// A protocol for any `UserEvent` where it has a `user` payload.
protocol UserSpecificEvent: EventWithPayload {
    var userId: UserId { get }
}

/// A protocol for any `ChannelEvent` where it has a  `channel` payload.
protocol ChannelSpecificEvent: EventWithPayload {
    var cid: ChannelId { get }
}

/// A protocol for any `MemberEvent` where it has a `member`, and `channel` payload.
protocol MemberEvent: ChannelSpecificEvent {
    var memberUserId: UserId { get }
}

/// A protocol for any `MessageEvent` where it has a `user`, `channel` and `message` payloads.
protocol MessageSpecificEvent: ChannelSpecificEvent, UserSpecificEvent {
    var messageId: MessageId { get }
}

/// A protocol for any  `ReactionEvent` where it has reaction with `message`, `channel`, `user` and `reaction` payload.
protocol ReactionEvent: MessageSpecificEvent {
    var reactionType: MessageReactionType { get }
    var reactionScore: Int { get }
}

/// A protocol for `NotificationMutesUpdatedEvent` which contains `me` AKA `currentUser` payload.
protocol CurrentUserEvent: EventWithPayload {
    var currentUserId: UserId { get }
}

/// A protocol custom event payload must conform to.
public protocol CustomEventPayload: Codable, Hashable {
    /// A type all events holding this payload have.
    static var eventType: EventType { get }
}
