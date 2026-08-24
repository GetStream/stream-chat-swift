//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChannelDeliveredRequestPayload: Sendable, Encodable, JSONEncodable {
    let latestDeliveredMessages: [DeliveredMessagePayload]?

    init(latestDeliveredMessages: [DeliveredMessagePayload]? = nil) {
        self.latestDeliveredMessages = latestDeliveredMessages
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case latestDeliveredMessages = "latest_delivered_messages"
    }
}
