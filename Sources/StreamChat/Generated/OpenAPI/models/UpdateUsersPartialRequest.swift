//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateUsersPartialRequest: Sendable, Encodable, JSONEncodable {
    let users: [UpdateUserPartialRequest]

    init(users: [UpdateUserPartialRequest]) {
        self.users = users
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case users
    }
}
