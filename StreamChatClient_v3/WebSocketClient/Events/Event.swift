//
// Event.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// An `Event` object representing an event in the chat system.
public protocol Event {
    /// The underlying raw type of the incoming string.
    static var eventRawType: String { get }
}

/// The DTO object mirroring the JSON representation of an event.
struct EventPayload<ExtraData: ExtraDataTypes>: Decodable {
    let eventType: String
    
    let connectionId: String?
    
    let channel: ChannelDetailPayload<ExtraData>?
    
    let currentUser: UserPayload<ExtraData.User>? // TODO: Create CurrentUserPayload?
    
    let cid: ChannelId?
    
    private enum CodingKeys: String, CodingKey {
        case connectionId = "connection_id"
        case channel
        case eventType = "type"
        case currentUser = "me"
        case cid
    }
}
