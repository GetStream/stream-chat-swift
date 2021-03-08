//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// An `Event` object representing an event in the chat system.
public protocol Event {}

/// An internal protocol marking the Events carrying the payload. This payload can be then used for additional work,
/// i.e. for storing the data to the database.
protocol EventWithPayload: Event {
    /// Type-erased event payload. Cast it to `EventPayload<ExtraData>` when you need to use it.
    var payload: Any { get }
}

/// A protocol for user `Event` where it has a user payload.
protocol EventWithUserPayload: EventWithPayload {
    var userId: UserId { get }
}

/// A protocol for a current user `Event` where it has `me` payload.
protocol EventWithCurrentUserPayload: EventWithPayload {
    var currentUserId: UserId { get }
}

/// A protocol for an owner `Event`. Event has 2 users where the owner of the event does something with another user, e.g. ban.
protocol EventWithOwnerPayload: EventWithPayload {
    var ownerId: UserId { get }
}

/// A protocol for channel `Event` where it has `cid` at least.
/// The combination of `EventWithChannelId` and `EventWithPayload` events required a `channel` object inside payload.
protocol EventWithChannelId: Event {
    var cid: ChannelId { get }
}

/// A protocol for message `Event` where it has a message payload.
protocol EventWithMessagePayload: EventWithUserPayload, EventWithChannelId {
    var messageId: MessageId { get }
}

/// A protocol for member `Event` where it has a member object and user object.
protocol EventWithMemberPayload: EventWithPayload {
    var userId: UserId { get }
}

/// A protocol for reaction `Event` where it has reacction with message payload.
protocol EventWithReactionPayload: EventWithMessagePayload {
    var reactionType: MessageReactionType { get }
    var reactionScore: Int { get }
}
