//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A lightweight object for decoding incoming events.
struct EventDecoderV2: AnyEventDecoder {
    func decode(from data: Data) throws -> Event {
        let decoder = JSONDecoder.default
        do {
            let response = try decoder.decode(StreamChatWSEvent.self, from: data)
            return response.rawValue
        } catch is ClientError.UnknownChannelEvent {
            return try decoder.decode(UnknownChannelEvent.self, from: data)
        } catch is ClientError.UnknownUserEvent {
            return try decoder.decode(UnknownUserEvent.self, from: data)
        } catch let error as ClientError.IgnoredEventType {
            throw error
        }
    }
}
