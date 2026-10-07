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

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(targetIds, forKey: .targetIds)
    }
}
