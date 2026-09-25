//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension CreateGuestResponse {
    /// The access token of the guest user, verified to belong to the returned user.
    func validatedToken() throws -> Token {
        let token = try Token(rawValue: accessToken)
        guard token.userId == user.id else {
            throw ClientError.InvalidToken("Token has different user_id")
        }
        return token
    }
}
