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
    
    /// Converts event DTO to event with evaluated models.
    ///
    /// If some model is missing in database `nil` is returned.
    ///
    /// - Parameter session: The database session used to load event models from database.
    func toDomainEvent(session: DatabaseSession) -> Event?
}

extension EventWithPayload {
    func toDomainEvent(session: DatabaseSession) -> Event? { nil }
}

/// A protocol for any `ChannelEvent` where it has a  `channel` payload.
protocol ChannelSpecificEvent: Event {
    var cid: ChannelId { get }
}

/// A protocol for any `MemberEvent` where it has a `member`, and `channel` payload.
public protocol MemberEvent: Event {
    var memberUserId: UserId { get }
    var cid: ChannelId { get }
}

/// A protocol custom event payload must conform to.
public protocol CustomEventPayload: Codable, Hashable {
    /// A type all events holding this payload have.
    static var eventType: EventType { get }
}
