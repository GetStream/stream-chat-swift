//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

final class CooldownTracker_Mock: CooldownTracker {
    var startCallCount = 0

    override func start(with cooldown: Int) {
        startCallCount += 1
        onChange?(cooldown)
    }
}
