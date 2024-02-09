//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// An `Event` object representing an event in the chat system.
public protocol Event {}

extension Event {
    var name: String {
        String(describing: Self.self).replacingOccurrences(of: "DTO", with: "")
    }
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
    var memberUserId: UserId { get }
    var cid: ChannelId { get }
}

/// A protocol custom event payload must conform to.
public protocol CustomEventPayload: Codable, Hashable {
    /// A type all events holding this payload have.
    static var eventType: EventType { get }
}
