//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension ClientError {
    public class IgnoredEventType: ClientError {
        override public var localizedDescription: String { "The incoming event type is not supported. Ignoring." }
    }

    public class EventDecoding: ClientError {
        override init(_ message: String, _ file: StaticString = #file, _ line: UInt = #line) {
            super.init(message, file, line)
        }

        init<T>(missingValue: String, for type: T.Type, _ file: StaticString = #file, _ line: UInt = #line) {
            super.init("`\(missingValue)` field can't be `nil` for the `\(type)` event.", file, line)
        }

        init(missingValue: String, for type: EventType, _ file: StaticString = #file, _ line: UInt = #line) {
            super.init("`\(missingValue)` field can't be `nil` for the `\(type.rawValue)` event.", file, line)
        }
    }
}

/// A type-erased wrapper protocol for `EventDecoder`.
protocol AnyEventDecoder {
    func decode(from: Data) throws -> Event
}
