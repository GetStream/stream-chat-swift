//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class UserPrivacySettings: @unchecked Sendable, Codable, JSONEncodable {
    public var deliveryReceipts: DeliveryReceiptsPrivacySettings?
    public var readReceipts: ReadReceiptsPrivacySettings?
    public var typingIndicators: TypingIndicatorPrivacySettings?

    init(
        deliveryReceipts: DeliveryReceiptsPrivacySettings? = nil,
        readReceipts: ReadReceiptsPrivacySettings? = nil,
        typingIndicators: TypingIndicatorPrivacySettings? = nil
    ) {
        self.deliveryReceipts = deliveryReceipts
        self.readReceipts = readReceipts
        self.typingIndicators = typingIndicators
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case deliveryReceipts = "delivery_receipts"
        case readReceipts = "read_receipts"
        case typingIndicators = "typing_indicators"
    }
}
