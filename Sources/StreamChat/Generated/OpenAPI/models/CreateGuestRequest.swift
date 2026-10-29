//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CreateGuestRequest: Sendable, Encodable, JSONEncodable {
    /// User request object
    let user: UserRequest

    init(user: UserRequest) {
        self.user = user
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(user, forKey: .user)
    }
}
