//
//  Event.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 06/04/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

/// An event type protocol.
public protocol EventType: Codable, CaseIterable {}

/// An event protocol.
public protocol Event: Decodable {
    associatedtype T = EventType // swiftlint:disable:this type_name
    
    /// An event type.
    var type: T { get }
    
    /// A user of the event.
    var user: User? { get }
}

extension Event {
    var cid: ChannelId? { nil }
}

/// Any event.
public enum AnyEvent {
    /// A client event.
    case client(ClientEvent)
    /// A channel event.
    case channel(ChannelEvent)
}

// MARK: Event Response

/// An event response.
public struct EventResponse<T: Decodable>: Decodable {
    /// An event (see `Event`).
    public let event: T
}

/// A channel event response.
public typealias ClientEventResponse = EventResponse<ClientEvent>
/// A channel event response.
public typealias ChannelEventResponse = EventResponse<ChannelEvent>
