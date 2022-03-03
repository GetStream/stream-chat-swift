//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension UserRequestBody {
    /// Returns a dummy user payload with the given UserId
    static func dummy(
        userId: UserId,
        name: String = .unique,
        imageURL: URL? = .unique(),
        extraData: [String: RawJSON] = [:]
    ) -> UserRequestBody {
        .init(id: userId, name: name, imageURL: imageURL, extraData: extraData)
    }
}
