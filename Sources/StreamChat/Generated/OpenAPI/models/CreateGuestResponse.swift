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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case accessToken = "access_token"
        case user
    }
}
