//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type describes the incoming JSON from `/sync` endpoint.
struct MissingEventsPayload: Decodable {
    private enum CodingKeys: String, CodingKey {
        case events
    }

    let events: [WSEvent]

    init(events: [WSEvent]) {
        self.events = events
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // We can't reach the raw event JSON from a KeyedDecodingContainer, so
        // we resort to decoding each event as RawJSON, re-serialize it, run it
        // through `EventDecoder.normalize`, and decode the result as `WSEvent`.
        let rawEvents = try container.decode([RawJSON].self, forKey: .events)
        events = rawEvents.compactMap { Self.decodeEvent(from: $0) }
    }

    /// Re-serializes a single event JSON through `EventDecoder`'s normalizer
    /// before strict OpenAPI decoding. Failures are logged and swallowed so a
    /// single malformed event doesn't drop the entire batch.
    private static func decodeEvent(from raw: RawJSON) -> WSEvent? {
        guard let data = try? JSONEncoder.default.encode(raw) else { return nil }
        let normalized = EventDecoder.normalize(data) ?? data
        do {
            return try JSONDecoder.default.decode(WSEvent.self, from: normalized)
        } catch {
            log.error("Failed to decode event in MissingEventsPayload: \(error)")
            return nil
        }
    }
}
