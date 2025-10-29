//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
        } catch let error as ClientError.IgnoredEventType {
            throw error
        }
    }
}

extension ClientError {
    public final class IgnoredEventType: ClientError, @unchecked Sendable {
        override public var localizedDescription: String { "The incoming event type is not supported. Ignoring." }
    }
}

/// A type-erased wrapper protocol for `EventDecoder`.
protocol AnyEventDecoder {
    func decode(from: Data) throws -> Event
}

extension EventDecoder: AnyEventDecoder {}
