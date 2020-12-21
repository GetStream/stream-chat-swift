//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

extension _ChatMessage {
    /// Says whether actions are available on the message (e.g. `edit`, `delete`, `resend`, etc.).
    var isInteractionEnabled: Bool {
        guard deletedAt == nil else { return false }

        return localState == nil || lastActionFailed
    }

    /// Says whether the last action (`send`, `edit` or `delete`) on the message failed.
    var lastActionFailed: Bool {
        switch localState {
        case .sendingFailed, .syncingFailed, .deletingFailed:
            return deletedAt == nil
        default:
            return false
        }
    }
}
