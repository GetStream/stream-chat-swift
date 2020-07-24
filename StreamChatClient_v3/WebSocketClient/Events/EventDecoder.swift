//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A lightweight object for decoding incoming events.
struct EventDecoder<ExtraData: ExtraDataTypes> {
    func decode(from data: Data) throws -> Event {
        let response = try JSONDecoder.default.decode(EventPayload<ExtraData>.self, from: data)
        return try response.event()
    }
}

extension ClientError {
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
