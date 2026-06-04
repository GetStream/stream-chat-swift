//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

extension QueryThreadsResponse {
    /// Returns a dummy `QueryThreadsResponse` with the given values.
    static func dummy(
        threads: [ThreadStateResponse] = [],
        next: String? = nil
    ) -> Self {
        .init(duration: "", next: next, prev: nil, threads: threads)
    }
}
