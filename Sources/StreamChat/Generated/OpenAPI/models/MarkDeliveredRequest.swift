//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MarkDeliveredRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var latestDeliveredMessages: [DeliveredMessagePayload]?

    init(latestDeliveredMessages: [DeliveredMessagePayload]? = nil) {
        self.latestDeliveredMessages = latestDeliveredMessages
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case latestDeliveredMessages = "latest_delivered_messages"
    }

    static func == (lhs: MarkDeliveredRequest, rhs: MarkDeliveredRequest) -> Bool {
        lhs.latestDeliveredMessages == rhs.latestDeliveredMessages
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(latestDeliveredMessages)
    }
}
