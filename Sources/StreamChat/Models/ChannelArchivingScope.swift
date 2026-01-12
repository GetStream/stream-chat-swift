//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The scope of the channel archiving action.
public enum ChannelArchivingScope: String {
    /// Channel is archived only for the currently connected user. Other channel members do not see channels as archived.
    case me
}
