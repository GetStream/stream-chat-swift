//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    /// Bridges the SDK's `EndpointPath` enum onto the generated `Endpoint`, whose `path` is a plain
    /// `String`. Lets the existing endpoint factories keep using `EndpointPath` while endpoints are
    /// migrated to the generated factories one at a time.
    convenience init(
        path: EndpointPath,
        method: EndpointMethod,
        queryItems: (Encodable & Sendable)? = nil,
        requiresConnectionId: Bool = false,
        requiresToken: Bool = true,
        body: (Encodable & Sendable)? = nil
    ) {
        self.init(
            path: path.value,
            method: method,
            queryItems: queryItems,
            requiresConnectionId: requiresConnectionId,
            requiresToken: requiresToken,
            shouldBeQueuedOffline: path.shouldBeQueuedOffline,
            body: body
        )
    }
}
