//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateUsersRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Object containing users
    var users: [String: UserRequest]

    init(users: [String: UserRequest]) {
        self.users = users
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case users
    }

    static func == (lhs: UpdateUsersRequest, rhs: UpdateUsersRequest) -> Bool {
        lhs.users == rhs.users
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(users)
    }
}
