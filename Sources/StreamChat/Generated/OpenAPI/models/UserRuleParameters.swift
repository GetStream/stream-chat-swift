//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UserRuleParameters: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var maxAge: String?

    init(maxAge: String? = nil) {
        self.maxAge = maxAge
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case maxAge = "max_age"
    }

    static func == (lhs: UserRuleParameters, rhs: UserRuleParameters) -> Bool {
        lhs.maxAge == rhs.maxAge
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(maxAge)
    }
}
