//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public extension PushPreference {
    /// The scope level of the push notifications.
    var level: PushPreferenceLevel {
        PushPreferenceLevel(rawValue: chatLevel ?? PushPreferenceLevel.all.rawValue)
    }
}
