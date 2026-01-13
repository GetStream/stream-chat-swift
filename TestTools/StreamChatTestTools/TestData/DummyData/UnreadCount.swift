//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension UnreadCountPayload {
    static var dummy: Self {
        .init(
            channels: Int.random(in: 0...Int.max),
            messages: Int.random(in: 0...Int.max),
            threads: Int.random(in: 0...Int.max)
        )
    }
}

extension UnreadCount {
    static var dummy: Self {
        .init(
            channels: Int.random(in: 0...Int.max),
            messages: Int.random(in: 0...Int.max),
            threads: Int.random(in: 0...Int.max)
        )
    }
}
