//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

extension ChatMessageListView {
    internal func reloadMessages(
        previousSnapshot: [ChatMessage],
        newSnapshot: [ChatMessage],
        completion: (() -> Void)? = nil
    ) {
        let changeset = StagedChangeset(
            source: previousSnapshot,
            target: newSnapshot
        )
        UIView.performWithoutAnimation {
            reload(
                using: changeset,
                with: .fade,
                reconfigure: { _ in false },
                setData: { [weak self] newMessages in
                    self?.onNewDataSource?(newMessages)
                },
                completion: { _ in completion?() }
            )
        }
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
