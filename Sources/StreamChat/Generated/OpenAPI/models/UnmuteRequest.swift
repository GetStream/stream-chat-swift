//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UnmuteRequest: Sendable, Encodable, JSONEncodable {
    /// User IDs to unmute
    let targetIds: [String]

    init(targetIds: [String]) {
        self.targetIds = targetIds
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case targetIds = "target_ids"
    }
}
