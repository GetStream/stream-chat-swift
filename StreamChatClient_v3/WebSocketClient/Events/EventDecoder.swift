//
// EventDecoder.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A lightweight object for decoding incoming events.
struct EventDecoder<ExtraData: ExtraDataTypes> {
    /// All supported event types by this decoder.
    let eventParsers: [(EventResponse<ExtraData>) throws -> Event?] = [
        HealthCheck.init,
        AddedToChannel.init
    ]
    
    func decode(data: Data) throws -> Event {
        let response = try JSONDecoder.default.decode(EventResponse<ExtraData>.self, from: data)
        
        for parser in eventParsers {
            if let decoded = try parser(response) {
                return decoded
            }
        }
        
        throw ClientError.UnsupportedEventType()
    }
}

extension ClientError {
    public class UnsupportedEventType: ClientError {
        public let localizedDescription = "The incoming event type is not supported. Ignoring."
    }
    
    public class EventDecodingError: ClientError {
        init(_ message: String, _ file: StaticString = #file, _ line: UInt = #line) {
            localizedDescription = message
            super.init(file, line)
        }
        
        init(missingValue: String, eventType: String, _ file: StaticString = #file, _ line: UInt = #line) {
            localizedDescription = "`\(missingValue)` can't be `nil` for the `\(eventType)` event."
            super.init(file, line)
        }
        
        let localizedDescription: String
    }
}

/// A type-erased wrapper protocol for `EventDecoder`.
protocol AnyEventDecoder {
    func decode(data: Data) throws -> Event
}

extension EventDecoder: AnyEventDecoder {}

/// The DTO object mirroring the JSON representation of the event.
struct EventResponse<ExtraData: ExtraDataTypes>: Decodable {
    let connectionId: String?
    
    let channelPayload: ChannelEndpointPayload<ExtraData>?
    
    let eventType: String
    
    private enum CodingKeys: String, CodingKey {
        case connectionId = "connection_id"
        case channelPayload = "channel"
        case eventType = "type"
    }
}
