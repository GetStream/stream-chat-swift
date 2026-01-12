//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The scope of the channel pinning action.
public enum ChannelPinningScope: String {
    /// Channel is pinned only for the currently connected user. Other channel members do not see channels as pinned.
    case me
}
