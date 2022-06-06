//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension Token {
    /// Returns a new `Token` with the provided `user_id` but not in JWT format.
    static func unique(userId: UserId = .unique) -> Self {
        .init(rawValue: .unique, userId: userId, expiration: nil)
    }
}
