//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

final class CooldownTracker_Mock: CooldownTracker {
    override func start(with cooldown: Int) {
        onChange?(cooldown)
    }
}
