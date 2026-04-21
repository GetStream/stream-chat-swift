//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GoogleVisionConfig: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var enabled: Bool?

    init(enabled: Bool? = nil) {
        self.enabled = enabled
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
    }

    static func == (lhs: GoogleVisionConfig, rhs: GoogleVisionConfig) -> Bool {
        lhs.enabled == rhs.enabled
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(enabled)
    }
}
