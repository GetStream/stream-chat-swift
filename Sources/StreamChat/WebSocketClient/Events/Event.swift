//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public extension Event {
    var name: String {
        String(describing: Self.self).replacingOccurrences(of: "DTO", with: "")
    }
}

extension WSEvent: @unchecked Sendable, Event {
    func healthcheck() -> HealthCheckInfo? {
        guard case .typeHealthCheckEvent(let event) = self else { return nil }
        return HealthCheckInfo(connectionId: event.connectionId)
    }

    func error() -> (any Error)? {
        // TODO: Handle connection.error here once it is generated as a WSEvent case.
        nil
    }
}

extension Event {
    var unwrappedEvent: Event {
        (self as? WSEvent)?.rawValue ?? self
    }
}

/// An internal protocol for events that can hydrate themselves from the database
/// to produce their public-facing domain event.
protocol EventDTO: Event {
    /// Converts event DTO to event with evaluated models.
    ///
    /// If some model is missing in database `nil` is returned.
    ///
    /// - Parameter session: The database session used to load event models from database.
    func toDomainEvent(session: DatabaseSession) -> Event?
}

extension EventDTO {
    func toDomainEvent(session: DatabaseSession) -> Event? { nil }
}

/// A protocol for any `ChannelEvent` where it has a  `channel` payload.
protocol ChannelSpecificEvent: Event {
    var cid: ChannelId { get }
}

/// A bounding protocol for all events that have unread counts.
public protocol HasUnreadCount: Event {
    /// If `ReadEvents` options is disabled the value is always `nil`.
    var unreadCount: UnreadCount? { get }
}

/// A protocol for any `MemberEvent` where it has a `member`, and `channel` payload.
public protocol MemberEvent: Event {
    var cid: ChannelId { get }
}

/// A protocol custom event payload must conform to.
public protocol CustomEventPayload: Codable, Hashable, Sendable {
    /// A type all events holding this payload have.
    static var eventType: EventType { get }
}
