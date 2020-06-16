//
// ChannelEvents.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol ChannelEvent: Event {
    associatedtype ExtraData: ExtraDataTypes
    
    var channelId: ChannelId { get }
}

public struct AddedToChannel<ExtraData: ExtraDataTypes>: ChannelEvent {
    public static var eventRawType: String { "notification.added_to_channel" }
    
    public var channelId: ChannelId {
        ChannelId(type: ChannelType(rawValue: channelPayload.channel.typeRawValue), id: channelPayload.channel.id)
    }
    
    let channelPayload: ChannelEndpointPayload<ExtraData>
    
    init?(from eventResponse: EventResponse<ExtraData>) throws {
        guard eventResponse.eventType == Self.eventRawType else { return nil }
        guard let channel = eventResponse.channelPayload else {
            throw ClientError.EventDecodingError("`channel` field can't be `nil` for the RemovedFromChannel event.")
        }
        self.init(channelPayload: channel)
    }
    
    init(channelPayload: ChannelEndpointPayload<ExtraData>) {
        self.channelPayload = channelPayload
    }
}
