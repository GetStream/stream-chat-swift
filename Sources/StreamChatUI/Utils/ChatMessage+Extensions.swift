//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

extension _ChatMessage {
    /// Says whether actions are available on the message (e.g. `edit`, `delete`, `resend`, etc.).
    var isInteractionEnabled: Bool {
        guard
            type != .ephemeral,
            deletedAt == nil
        else { return false }

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

    /// Says whether the message is part of message thread.
    var isPartOfThread: Bool {
        let isThreadStart = replyCount > 0
        let isThreadReplyInChannel = showReplyInChannel

        return isThreadStart || isThreadReplyInChannel
    }

    /// The text which should be shown in a text view inside the message bubble.
    var textContent: String? {
        guard type != .ephemeral else {
            return nil
        }

        guard deletedAt == nil else {
            return L10n.Message.deletedMessagePlaceholder
        }

        return text
    }

    /// Says whether the message is visible for current user only.
    var onlyVisibleForCurrentUser: Bool {
        guard isSentByCurrentUser else {
            return false
        }

        return deletedAt != nil || type == .ephemeral
    }
}
