//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public extension PushPreference {
    /// The scope level of the push notifications.
    var level: PushPreferenceLevel {
        chatLevel
    }
}
