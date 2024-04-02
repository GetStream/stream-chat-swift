//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    // MARK: - Fetch Threads List
    
    static func threads(query: ThreadListQuery) -> Endpoint<ThreadListPayload> {
        .init(
            path: .threads,
            method: .post,
            queryItems: nil,
            requiresConnectionId: query.watch == true,
            body: query
        )
    }
}
