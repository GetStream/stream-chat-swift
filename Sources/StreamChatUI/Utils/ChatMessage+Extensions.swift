//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

extension _ChatMessage {
    /// A boolean value that checks if actions are available on the message (e.g. `edit`, `delete`, `resend`, etc.).
    var isInteractionEnabled: Bool {
        guard
            type != .ephemeral,
            deletedAt == nil
        else { return false }

        return localState == nil || lastActionFailed
    }

    /// A boolean value that checks if the last action (`send`, `edit` or `delete`) on the message failed.
    var lastActionFailed: Bool {
        switch localState {
        case .sendingFailed, .syncingFailed, .deletingFailed:
            return deletedAt == nil
        default:
            return false
        }
    }

    /// A boolean value that checks if the message is the root of a thread.
    var isRootOfThread: Bool {
        replyCount > 0
    }

    /// A boolean value that checks if the message is the part (child) of a thread.
    var isPartOfThread: Bool {
        parentMessageId != nil
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

    /// A boolean value that checks if the message is visible for current user only.
    var onlyVisibleForCurrentUser: Bool {
        guard isSentByCurrentUser else {
            return false
        }

        return deletedAt != nil || type == .ephemeral
    }

    /// Returns last active thread participant.
    var lastActiveThreadParticipant: _ChatUser<ExtraData.User>? {
        func sortingCriteriaDate(_ user: _ChatUser<ExtraData.User>) -> Date {
            user.lastActiveAt ?? user.userUpdatedAt
        }

        return threadParticipants
            .sorted(by: { sortingCriteriaDate($0) > sortingCriteriaDate($1) })
            .first
    }
}
