//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension UnreadCount {
    static var dummy: Self {
        .init(
            channels: Int.random(in: 0...Int.max),
            messages: Int.random(in: 0...Int.max),
            threads: Int.random(in: 0...Int.max)
        )
    }
}
