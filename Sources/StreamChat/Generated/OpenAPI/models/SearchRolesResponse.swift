//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SearchRolesResponse: Sendable, Decodable {
    /// Matching roles, sorted ascending by name
    let roles: [Role]

    init(roles: [Role]) {
        self.roles = roles
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case roles
    }
}
