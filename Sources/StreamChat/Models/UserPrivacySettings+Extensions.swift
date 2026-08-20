//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// The generated memberwise init orders its parameters alphabetically. Keep the
// previously hand-written order as the public one.
public extension UserPrivacySettings {
    convenience init(
        typingIndicators: TypingIndicatorPrivacySettings? = nil,
        readReceipts: ReadReceiptsPrivacySettings? = nil,
        deliveryReceipts: DeliveryReceiptsPrivacySettings? = nil
    ) {
        self.init(
            deliveryReceipts: deliveryReceipts,
            readReceipts: readReceipts,
            typingIndicators: typingIndicators
        )
    }
}
