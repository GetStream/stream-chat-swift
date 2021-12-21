//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// Describes user/channel mute details.
public struct MuteDetails: Equatable {
    /// The time when the mute action was taken.
    public let createdAt: Date
    /// The time when the mute was updated.
    public let updatedAt: Date?
}
