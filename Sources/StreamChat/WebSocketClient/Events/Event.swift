//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// An `Event` object representing an event in the chat system.
public protocol Event {}

/// An internal protocol marking the Events carrying the payload. This payload can be then used for additional work,
/// i.e. for storing the data to the database.
protocol EventWithPayload: Event {
    /// Type-erased event payload. Cast it to `EventPayload` when you need to use it.
    var payload: Any { get }
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
