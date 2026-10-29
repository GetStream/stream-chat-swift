//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateUsersPartialRequest: Sendable, Encodable, JSONEncodable {
    let users: [UpdateUserPartialRequest]

    init(users: [UpdateUserPartialRequest]) {
        self.users = users
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(users, forKey: .users)
    }
}
