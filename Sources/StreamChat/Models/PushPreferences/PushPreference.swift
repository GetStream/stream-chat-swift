//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The push preference details.
public struct PushPreference: Equatable {
    /// The scope level of the push notifications.
    public let level: PushPreferenceLevel
    /// If provided the notifications will be disabled until the set date.
    public let disabledUntil: Date?
}
