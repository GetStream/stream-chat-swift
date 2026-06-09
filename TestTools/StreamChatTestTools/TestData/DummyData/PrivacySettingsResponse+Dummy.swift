//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension PrivacySettingsResponse {
    static func dummy(
        readReceipts: Bool = true,
        typingIndicators: Bool = true,
        deliveryReceipts: Bool = true
    ) -> PrivacySettingsResponse {
        PrivacySettingsResponse(
            deliveryReceipts: .init(enabled: deliveryReceipts),
            readReceipts: .init(enabled: readReceipts),
            typingIndicators: .init(enabled: typingIndicators)
        )
    }
}
