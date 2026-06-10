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
            // TODO: Remove once connection.ok and connection.error are generated as
            // WSEvent cases and WSEvent.healthcheck()/error() handle them from the
            // generated WSEvent value.
            if let connectedEvent = try? decoder.decode(ConnectedEvent.self, from: data) {
                return connectedEvent
            } else if let connectionErrorEvent = try? decoder.decode(ConnectionErrorEvent.self, from: data) {
                return connectionErrorEvent
            } else if let unknownChannelEvent = try? decoder.decode(UnknownChannelEvent.self, from: data) {
                return unknownChannelEvent
            } else if let unknownUserEvent = try? decoder.decode(UnknownUserEvent.self, from: data) {
                return unknownUserEvent
            }
            // Surface the underlying WSEvent decoding error here. Otherwise the only thing logged is the
            // stream-core fallback that tries to decode the payload as an APIErrorContainer, which reports a
            // misleading "Key 'error' not found" instead of the real failure.
            log.warning("Failed to decode WSEvent: \(error)", subsystems: .webSocket)
            throw ClientError.EventDecoding(missingValue: "\(error)", for: "unknown")
        }
    }

    func decode(from wsEvent: WSEvent) throws -> Event {
        wsEvent
    }
}

extension EventDecoder: AnyEventDecoder {}
