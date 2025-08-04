//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class CooldownTracker_Mock: CooldownTracker, @unchecked Sendable {
    var startCallCount = 0

    override func start(with cooldown: Int) {
        startCallCount += 1
        onChange?(cooldown)
    }
}
