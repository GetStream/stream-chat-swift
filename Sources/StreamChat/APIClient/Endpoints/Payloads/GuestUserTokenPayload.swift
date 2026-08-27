//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

struct GuestUserTokenPayload: Decodable {
    private enum CodingKeys: String, CodingKey {
        case user
        case token = "access_token"
    }

    let user: OwnUserResponse
    let token: Token

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let user = try container.decode(OwnUserResponse.self, forKey: .user)
        let token = try container.decode(Token.self, forKey: .token)

        guard user.id == token.userId else {
            throw ClientError.InvalidToken("Token has different user_id")
        }

        self.init(user: user, token: token)
    }

    init(
        user: OwnUserResponse,
        token: Token
    ) {
        self.user = user
        self.token = token
    }
}
