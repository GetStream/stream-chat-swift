//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SendEventRequest: Sendable, Encodable, JSONEncodable {
    let event: EventRequest

    init(event: EventRequest) {
        self.event = event
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(event, forKey: .event)
    }
}
