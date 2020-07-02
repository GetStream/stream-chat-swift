//
// ChannelEvents.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol ChannelEvent: Event {
    var cid: ChannelId { get }
}

public struct AddedToChannel<ExtraData: ExtraDataTypes>: ChannelEvent, EventWithPayload {
    public static var eventRawType: String { "notification.added_to_channel" }
    
    public let cid: ChannelId
    let payload: Any
    
    init?(from eventPayload: EventPayload<ExtraData>) throws {
        guard eventPayload.eventType == Self.eventRawType else { return nil }
        guard eventPayload.channel != nil else {
            throw ClientError.EventDecodingError("`channel` field can't be `nil` for the `AddedToChannel` event.")
        }
        
        guard let cid = eventPayload.cid else {
            throw ClientError.EventDecodingError("`cid` field can't be `nil` for the `AddedToChannel` event.")
        }
        
        self.init(cid: cid, eventPayload: eventPayload)
    }
    
    init(cid: ChannelId, eventPayload: EventPayload<ExtraData>) {
        self.cid = cid
        payload = eventPayload as Any
    }
}
