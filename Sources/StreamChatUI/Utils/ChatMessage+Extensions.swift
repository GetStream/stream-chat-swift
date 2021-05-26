//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

public extension _ChatMessage {
    /// A boolean value that checks if actions are available on the message (e.g. `edit`, `delete`, `resend`, etc.).
    var isInteractionEnabled: Bool {
        guard
            type != .ephemeral,
            isDeleted == false
        else { return false }

        return localState == nil || isLastActionFailed
    }

    /// A boolean value that checks if the last action (`send`, `edit` or `delete`) on the message failed.
    var isLastActionFailed: Bool {
        guard isDeleted == false else { return false }

        switch localState {
        case .sendingFailed, .syncingFailed, .deletingFailed:
            return true
        default:
            return false
        }
    }

    /// A boolean value that checks if the message is the root of a thread.
    var isRootOfThread: Bool {
        replyCount > 0
    }

    /// A boolean value that checks if the message is part of a thread.
    var isPartOfThread: Bool {
        parentMessageId != nil
    }

    /// The text which should be shown in a text view inside the message bubble.
    var textContent: String? {
        guard type != .ephemeral else {
            return nil
        }

        return isDeleted ? L10n.Message.deletedMessagePlaceholder : text
    }

    /// A boolean value that checks if the message is visible for current user only.
    var isOnlyVisibleForCurrentUser: Bool {
        guard isSentByCurrentUser else {
            return false
        }

        return isDeleted || type == .ephemeral
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

    /// A boolean value that says if the message is deleted.
    var isDeleted: Bool {
        deletedAt != nil
    }
}
