//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

public extension ChatMessage {
    /// A boolean value that checks if actions are available on the message (e.g. `edit`, `delete`, `resend`, etc.).
    var isInteractionEnabled: Bool {
        guard
            type != .ephemeral, type != .system, type != .error,
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
        replyCount > 0 || !latestReplies.isEmpty
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

    /// Returns last active thread participant.
    var lastActiveThreadParticipant: ChatUser? {
        func sortingCriteriaDate(_ user: ChatUser) -> Date {
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

    /// A boolean value that determines whether the text message should be rendered as large emojis
    ///
    /// By default, any string which comprises of ONLY emojis of length 3 or less is displayed as large emoji
    ///
    /// Note that for messages sent with attachments, large emojis aren's rendered
    var shouldRenderAsJumbomoji: Bool {
        guard attachmentCounts.isEmpty, let textContent = textContent, !textContent.isEmpty else { return false }
        return textContent.count <= 3 && textContent.containsOnlyEmoji
    }

    /// When a message that has been synced gets edited but is bounced by the moderation API it will return true to this state.
    var failedToBeEditedDueToModeration: Bool {
        localState == .syncingFailed && isBounced == true
    }

    /// When a message fails to get synced because it was bounced by the moderation API it will return true to this state.
    var failedToBeSentDueToModeration: Bool {
        localState == .sendingFailed && isBounced == true
    }
}

public extension ChatMessage {
    /// A boolean value that checks if the message is visible for current user only.
    @available(
        *,
        deprecated,
        message: "This property is deprecated because it does not take `deletedMessagesVisability` setting into account."
    )
    var isOnlyVisibleForCurrentUser: Bool {
        guard isSentByCurrentUser else {
            return false
        }

        return isDeleted || type == .ephemeral
    }
}
