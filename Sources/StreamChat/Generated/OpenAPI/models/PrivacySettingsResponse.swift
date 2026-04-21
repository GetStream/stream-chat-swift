//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PrivacySettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var deliveryReceipts: DeliveryReceiptsResponse?
    var readReceipts: ReadReceiptsResponse?
    var typingIndicators: TypingIndicatorsResponse?

    init(deliveryReceipts: DeliveryReceiptsResponse? = nil, readReceipts: ReadReceiptsResponse? = nil, typingIndicators: TypingIndicatorsResponse? = nil) {
        self.deliveryReceipts = deliveryReceipts
        self.readReceipts = readReceipts
        self.typingIndicators = typingIndicators
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case deliveryReceipts = "delivery_receipts"
        case readReceipts = "read_receipts"
        case typingIndicators = "typing_indicators"
    }

    static func == (lhs: PrivacySettingsResponse, rhs: PrivacySettingsResponse) -> Bool {
        lhs.deliveryReceipts == rhs.deliveryReceipts &&
            lhs.readReceipts == rhs.readReceipts &&
            lhs.typingIndicators == rhs.typingIndicators
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(deliveryReceipts)
        hasher.combine(readReceipts)
        hasher.combine(typingIndicators)
    }
}
