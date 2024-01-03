//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

extension ChatMessageListView {
    internal func reloadMessages(
        previousSnapshot: [ChatMessage],
        newSnapshot: [ChatMessage],
        with animation: @autoclosure () -> RowAnimation,
        completion: (() -> Void)? = nil
    ) {
        let changeset = StagedChangeset(
            source: previousSnapshot,
            target: newSnapshot
        )
        // This is need because DiffKit doesn't provide a completion block for when the reload is finished.
        // The CATransaction notifies when animations are finished executing between begin() and commit().
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        reload(
            using: changeset,
            with: animation()
        ) { [weak self] newMessages in
            self?.onNewDataSource?(newMessages)
        }
        CATransaction.commit()
    }
}

extension ChatMessage: Differentiable {
    public func isContentEqual(to source: ChatMessage) -> Bool {
        id == source.id
            && updatedAt == source.updatedAt
            && replyCount == source.replyCount
            && isShadowed == source.isShadowed
            && showReplyInChannel == source.showReplyInChannel
            && text == source.text
            && localState == source.localState
            && type == source.type
            && command == source.command
            && arguments == source.arguments
            && parentMessageId == source.parentMessageId
            && isFlaggedByCurrentUser == source.isFlaggedByCurrentUser
            && reactionCounts == source.reactionCounts
            && reactionScores == source.reactionScores
            && extraData == source.extraData
            && currentUserReactionsCount == source.currentUserReactionsCount
            && threadParticipantsCount == source.threadParticipantsCount
            && readByCount == source.readByCount
            && quotedMessage == source.quotedMessage
            && author == source.author
            && allAttachments == source.allAttachments
    }
}
