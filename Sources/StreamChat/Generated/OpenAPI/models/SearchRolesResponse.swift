//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SearchRolesResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var duration: String
    /// Matching roles, sorted ascending by name
    var roles: [Role]

    init(duration: String, roles: [Role]) {
        self.duration = duration
        self.roles = roles
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case roles
    }

    static func == (lhs: SearchRolesResponse, rhs: SearchRolesResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.roles == rhs.roles
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(roles)
    }
}
