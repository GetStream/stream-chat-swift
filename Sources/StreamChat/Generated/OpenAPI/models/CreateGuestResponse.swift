//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CreateGuestResponse: Sendable, Decodable {
    /// the access token to authenticate the user
    let accessToken: String
    /// User response object
    let user: UserPayload

    init(accessToken: String, user: UserPayload) {
        self.accessToken = accessToken
        self.user = user
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.accessToken = try container.decode(String.self, forKey: .accessToken)
        self.user = try container.decode(UserPayload.self, forKey: .user)
    }
}
