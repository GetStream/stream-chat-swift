//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class CooldownTracker_Mock: CooldownTracker, @unchecked Sendable {
    var startCallCount = 0
    var startedCooldowns: [Int] = []

    override func start(with cooldown: Int) {
        startCallCount += 1
        startedCooldowns.append(cooldown)
        onChange?(cooldown)
    }
}
