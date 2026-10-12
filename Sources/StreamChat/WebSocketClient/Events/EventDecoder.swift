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
            // Custom event types are surfaced through the public unknown event types. Known event types which
            // failed to decode must not be reported as unknown events, otherwise the failure goes unnoticed.
            let type = (try? decoder.decode(EventTypeEnvelope.self, from: data))?.type ?? "unknown"
            if type == EventType.channelCreated.rawValue { throw ClientError.IgnoredEventType() }
            if isUnknownEventType(error), let event = try? decodeUnknownEvent(from: data) { return event }
            if type == EventType.aiTypingIndicatorChanged.rawValue,
               let event = try? decoder.decode(WSEvent.self, from: flattenCustomData(in: data)) {
                return event
            }
            throw ClientError.EventDecoding(failedParsingValue: "WSEvent", for: type, with: error)
        }
    }

    /// `WSEvent` reports an event type it does not know about as a type mismatch against itself.
    private func isUnknownEventType(_ error: Error) -> Bool {
        guard case let DecodingError.typeMismatch(type, _) = error else { return false }
        return type == WSEvent.Type.self
    }

    // The v2 WebSocket nests the fields of an event sent with SendEvent in `custom`, while
    // `ai_indicator.update` reads them at the root, where the v1 WebSocket flattens them.
    private func flattenCustomData(in data: Data) throws -> Data {
        var json = try JSONDecoder.default.decode([String: RawJSON].self, from: data)
        guard case let .dictionary(custom)? = json["custom"] else { return data }
        json.merge(custom) { root, _ in root }
        return try JSONEncoder.default.encode(json)
    }

    private func decodeUnknownEvent(from data: Data) throws -> Event {
        let decoder = JSONDecoder.default
        if let event = try? decoder.decode(UnknownChannelEvent.self, from: data) { return event }
        return try decoder.decode(UnknownUserEvent.self, from: data)
    }
}

extension EventDecoder: AnyEventDecoder {}
