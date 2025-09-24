//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// The push global preference details.
public struct UserPushPreference {
    /// The scope level of the push notifications.
    public let level: PushPreferenceLevel
    /// If provided the notifications will be disabled until the set date.
    public let disabledUntil: Date?
}
