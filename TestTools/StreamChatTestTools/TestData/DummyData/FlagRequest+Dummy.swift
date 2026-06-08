//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension FlagRequest {
    /// Returns a dummy flag request.
    static func dummy(
        custom: [String: RawJSON]? = nil,
        entityId: String = .unique,
        entityType: String = "message",
        reason: String? = nil
    ) -> FlagRequest {
        FlagRequest(
            custom: custom,
            entityId: entityId,
            entityType: entityType,
            reason: reason
        )
    }
}
