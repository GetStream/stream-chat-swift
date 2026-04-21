//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BlockActionRequestPayload: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Reason for blocking
    var reason: String?

    init(reason: String? = nil) {
        self.reason = reason
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case reason
    }

    static func == (lhs: BlockActionRequestPayload, rhs: BlockActionRequestPayload) -> Bool {
        lhs.reason == rhs.reason
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(reason)
    }
}
