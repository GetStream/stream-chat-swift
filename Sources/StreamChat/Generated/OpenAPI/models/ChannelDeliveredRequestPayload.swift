//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChannelDeliveredRequestPayload: Sendable, Encodable, JSONEncodable {
    let latestDeliveredMessages: [DeliveredMessagePayload]?

    init(latestDeliveredMessages: [DeliveredMessagePayload]? = nil) {
        self.latestDeliveredMessages = latestDeliveredMessages
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(latestDeliveredMessages, forKey: .latestDeliveredMessages)
    }
}
