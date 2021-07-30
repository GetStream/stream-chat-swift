//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type used to send custom event payload to backend.
struct CustomEventRequestBody<Payload: CustomEventPayload>: Encodable {
    let payload: Payload
    
    func encode(to encoder: Encoder) throws {
        let data = try JSONEncoder.default.encode(payload)
        var json = try JSONDecoder.default.decode(CustomData.self, from: data)
        json[EventPayload.CodingKeys.eventType.rawValue] = .string(type(of: payload).eventType.rawValue)
        try json.encode(to: encoder)
    }
}
