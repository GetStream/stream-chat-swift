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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.roles = try container.decodeArrayIgnoringFailures([Role].self, forKey: .roles)
    }
}
