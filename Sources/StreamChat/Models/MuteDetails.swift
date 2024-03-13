//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Describes user/channel mute details.
public struct MuteDetails: Equatable {
    /// The time when the mute action was taken.
    public let createdAt: Date
    /// The time when the mute was updated.
    public let updatedAt: Date?
    /// The expiration date of the pinning. Infinite expiration in case it is `nil`.
    public let expiresAt: Date?
}
