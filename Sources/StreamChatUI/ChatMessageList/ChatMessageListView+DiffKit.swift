//
// Copyright © 2023 Stream.io Inc. All rights reserved.
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
            && text == source.text
            && type == source.type
            && command == source.command
            && arguments == source.arguments
            && parentMessageId == source.parentMessageId
            && showReplyInChannel == source.showReplyInChannel
            && replyCount == source.replyCount
            && extraData == source.extraData
            && quotedMessage == source.quotedMessage
            && isShadowed == source.isShadowed
            && currentUserReactions.count == source.currentUserReactions.count
            && reactionCounts == source.reactionCounts
            && reactionScores == source.reactionScores
            && threadParticipants.count == source.threadParticipants.count
            && localState == source.localState
            && isFlaggedByCurrentUser == source.isFlaggedByCurrentUser
            && readBy.count == source.readBy.count
            && allAttachments.map(\.uploadingState) == source.allAttachments.map(\.uploadingState)
            && areEqual(allAttachments.map(\.payload), source.allAttachments.map(\.payload))
    }

    private func areEqual(_ first: Any, _ second: Any) -> Bool {
        if let equatableOne = first as? any Equatable, let equatableTwo = second as? any Equatable {
            return equatableOne.isEqual(equatableTwo)
        }
        
        if let arrayFirst = first as? [any Equatable], let secondArray = second as? [any Equatable] {
            return zip(arrayFirst, secondArray).allSatisfy { areEqual($0, $1) }
        }

        return false
    }
}

private extension Equatable {
    func isEqual(_ other: any Equatable) -> Bool {
        guard let other = other as? Self else {
            return other.isExactlyEqual(self)
        }
        return self == other
    }

    private func isExactlyEqual(_ other: any Equatable) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return self == other
    }
}
