//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

struct GuestUserTokenPayload<ExtraData: UserExtraData>: Decodable {
    private enum CodingKeys: String, CodingKey {
        case user
        case token = "access_token"
    }

    let user: CurrentUserPayload<ExtraData>
    let token: Token
}
