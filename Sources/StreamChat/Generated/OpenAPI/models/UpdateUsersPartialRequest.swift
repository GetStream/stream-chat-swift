//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateUsersPartialRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var users: [UpdateUserPartialRequest]

    init(users: [UpdateUserPartialRequest]) {
        self.users = users
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case users
    }

    static func == (lhs: UpdateUsersPartialRequest, rhs: UpdateUsersPartialRequest) -> Bool {
        lhs.users == rhs.users
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(users)
    }
}
