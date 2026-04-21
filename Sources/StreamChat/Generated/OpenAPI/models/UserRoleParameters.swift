//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UserRoleParameters: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var `operator`: String?
    var role: String?

    init(operator: String? = nil, role: String? = nil) {
        self.operator = `operator`
        self.role = role
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case `operator`
        case role
    }

    static func == (lhs: UserRoleParameters, rhs: UserRoleParameters) -> Bool {
        lhs.operator == rhs.operator &&
            lhs.role == rhs.role
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(`operator`)
        hasher.combine(role)
    }
}
