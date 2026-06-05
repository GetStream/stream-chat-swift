//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension UserRequest {
    /// Returns a dummy user payload with the given UserId
    static func dummy(
        userId: UserId,
        name: String = .unique,
        imageURL: URL? = .unique(),
        extraData: [String: RawJSON] = [:]
    ) -> UserRequest {
        .init(custom: extraData, id: userId, image: imageURL?.absoluteString, name: name)
    }
}
