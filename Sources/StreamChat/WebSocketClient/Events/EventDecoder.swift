//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A lightweight object for decoding incoming events.
struct EventDecoder {
    private struct EventTypeEnvelope: Decodable {
        let type: String
    }

    func decode(from data: Data) throws -> Event {
        let decoder = JSONDecoder.default
        do {
            return try decoder.decode(WSEvent.self, from: data)
        } catch {
            // `connection.ok` and `connection.error` are not part of the generated `WSEvent`, and custom
            // event types are surfaced through the public unknown event types. Known event types which
            // failed to decode must not be reported as unknown events, otherwise the failure goes unnoticed.
            if let event = try? decoder.decode(ConnectedEvent.self, from: data) { return event }
            if let event = try? decoder.decode(ConnectionErrorEvent.self, from: data) { return event }
            let type = (try? decoder.decode(EventTypeEnvelope.self, from: data))?.type ?? "unknown"
            if type == EventType.channelCreated.rawValue { throw ClientError.IgnoredEventType() }
            if isUnknownEventType(error), let event = try? decodeUnknownEvent(from: data) { return event }
            throw ClientError.EventDecoding(failedParsingValue: "WSEvent", for: type, with: error)
        }
    }

    /// `WSEvent` reports an event type it does not know about as a type mismatch against itself.
    private func isUnknownEventType(_ error: Error) -> Bool {
        guard case let DecodingError.typeMismatch(type, _) = error else { return false }
        return type == WSEvent.Type.self
    }

    private func decodeUnknownEvent(from data: Data) throws -> Event {
        let decoder = JSONDecoder.default
        if let event = try? decoder.decode(UnknownChannelEvent.self, from: data) { return event }
        return try decoder.decode(UnknownUserEvent.self, from: data)
    }
}

extension EventDecoder: AnyEventDecoder {}
