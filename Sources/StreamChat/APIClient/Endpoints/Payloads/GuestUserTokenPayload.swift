//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

struct GuestUserTokenPayload: Decodable {
    private enum CodingKeys: String, CodingKey {
        case user
        case token = "access_token"
    }

    let user: CurrentUserPayload
    let token: Token

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let user = try container.decode(CurrentUserPayload.self, forKey: .user)
        let token = try container.decode(Token.self, forKey: .token)

        guard user.id == token.userId else {
            throw ClientError.InvalidToken("Token has different user_id")
        }

        self.init(user: user, token: token)
    }

    init(
        user: CurrentUserPayload,
        token: Token
    ) {
        self.user = user
        self.token = token
    }
}
