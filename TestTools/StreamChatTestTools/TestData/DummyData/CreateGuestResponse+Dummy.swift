//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension CreateGuestResponse {
    static func dummy(
        user: OwnUserResponse = .dummy(userId: "", role: .user),
        token: Token = .development(userId: .unique)
    ) -> CreateGuestResponse {
        let userResponse = user.asUserResponse()
        userResponse.id = token.userId
        return CreateGuestResponse(accessToken: token.rawValue, duration: "", user: userResponse)
    }
}
