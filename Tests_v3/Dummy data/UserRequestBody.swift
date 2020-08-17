//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatClient

extension UserRequestBody {
    /// Returns a dummy user payload with the given UserId
    static func dummy<T: UserExtraData>(userId: UserId, extraData: T = .defaultValue) -> UserRequestBody<T> {
        .init(id: userId, extraData: extraData)
    }
}
