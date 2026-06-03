//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A lightweight object for decoding incoming events.
struct EventDecoder {
    func decode(from data: Data) throws -> Event {
        let decoder = JSONDecoder.default
        do {
            let wsEvent = try decoder.decode(WSEvent.self, from: data)
            return wsEvent
        } catch {
            // TODO: Remove once connection.error is generated as a WSEvent case and
            // WSEvent.error() handles it from the generated WSEvent value.
            if let connectionErrorEvent = try? decoder.decode(ConnectionErrorEvent.self, from: data) {
                return connectionErrorEvent
            } else if let unknownChannelEvent = try? decoder.decode(UnknownChannelEvent.self, from: data) {
                return unknownChannelEvent
            } else if let unknownUserEvent = try? decoder.decode(UnknownUserEvent.self, from: data) {
                return unknownUserEvent
            }
            throw ClientError.EventDecoding(missingValue: "\(error)", for: "unknown")
        }
    }

    func decode(from wsEvent: WSEvent) throws -> Event {
        wsEvent
    }
}

extension EventDecoder: AnyEventDecoder {}
