//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A lightweight object for decoding incoming events.
struct EventDecoder: AnyEventDecoder {
    func decode(from data: Data) throws -> Event {
        let decoder = JSONDecoder.default
        do {
            let response = try decoder.decode(WSEvent.self, from: data)
            return response.rawValue
        } catch is ClientError.UnknownChannelEvent {
            do {
                return try decoder.decode(UnknownChannelEvent.self, from: data)
            } catch {
                return try decoder.decode(UnknownUserEvent.self, from: data)
            }
        } catch is ClientError.UnknownUserEvent {
            return try decoder.decode(UnknownUserEvent.self, from: data)
        } catch let error as ClientError.IgnoredEventType {
            throw error
        } catch {
            throw error
        }
    }
}

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
