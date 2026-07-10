//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SearchRolesResponse: Sendable, Codable, JSONEncodable {
    let duration: String
    /// Matching roles, sorted ascending by name
    let roles: [Role]

    init(duration: String, roles: [Role]) {
        self.duration = duration
        self.roles = roles
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case roles
    }
}
