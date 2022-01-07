//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// A lightweight object for decoding incoming events.
struct EventDecoder {
    func decode(from data: Data) throws -> Event {
        let decoder = JSONDecoder.default
        do {
            let response = try decoder.decode(EventPayload.self, from: data)
            return try response.event()
        } catch is ClientError.UnknownChannelEvent {
            return try decoder.decode(UnknownChannelEvent.self, from: data)
        } catch is ClientError.UnknownUserEvent {
            return try decoder.decode(UnknownUserEvent.self, from: data)
        }
    }
}

extension ClientError {
    public class UnsupportedEventType: ClientError {
        override public var localizedDescription: String { "The incoming event type is not supported. Ignoring." }
    }
    
    public class EventDecoding: ClientError {
        override init(_ message: String, _ file: StaticString = #file, _ line: UInt = #line) {
            super.init(message, file, line)
        }
        
        init<T>(missingValue: String, for type: T.Type, _ file: StaticString = #file, _ line: UInt = #line) {
            super.init("`\(missingValue)` field can't be `nil` for the `\(type)` event.", file, line)
        }
    }
}

/// A type-erased wrapper protocol for `EventDecoder`.
protocol AnyEventDecoder {
    func decode(from: Data) throws -> Event
}

extension EventDecoder: AnyEventDecoder {}
