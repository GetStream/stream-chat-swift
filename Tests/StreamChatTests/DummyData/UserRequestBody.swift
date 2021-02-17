//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension UserRequestBody {
    /// Returns a dummy user payload with the given UserId
    static func dummy<T: UserExtraData>(userId: UserId, extraData: T = .defaultValue) -> UserRequestBody<T> {
        .init(id: userId, name: .unique, imageURL: .unique(), extraData: extraData)
    }
}
