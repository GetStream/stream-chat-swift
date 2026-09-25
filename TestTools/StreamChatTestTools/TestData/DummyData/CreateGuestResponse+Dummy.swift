//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension CreateGuestResponse {
    static func dummy(token: Token = .development(userId: .unique), user: UserPayload? = nil) -> CreateGuestResponse {
        CreateGuestResponse(
            accessToken: token.rawValue,
            user: user ?? .dummy(userId: token.userId, role: .guest)
        )
    }
}
