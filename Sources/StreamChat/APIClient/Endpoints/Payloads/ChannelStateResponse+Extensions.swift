//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension ChannelStateResponse {
    /// Returns the newest message from `messages` in O(1) assuming messages are sorted by `createdAt`.
    var newestMessage: MessageResponse? {
        guard let first = messages.first, let last = messages.last else { return nil }

        return first.createdAt > last.createdAt ? first : last
    }
}
