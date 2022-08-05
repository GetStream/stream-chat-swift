//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import DifferenceKit
import StreamChat
import UIKit

extension ChatMessageListView {
    internal func reloadMessages(
        previousSnapshot: [ChatMessage],
        newSnapshot: [ChatMessage],
        with animation: @autoclosure () -> RowAnimation,
        completion: (() -> Void)? = nil
    ) {
        let source = previousSnapshot.map(DiffChatMessage.init)
        let target = newSnapshot.map(DiffChatMessage.init)
        let changeset = StagedChangeset(
            source: source,
            target: target
        )
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        reload(
            using: changeset,
            with: animation()
        ) { [weak self] diffMessages in
            self?.onNewDataSource?(diffMessages.map(\.message))
        }
        CATransaction.commit()
    }
}

private struct DiffChatMessage: Hashable, Differentiable {
    let message: ChatMessage

    func isContentEqual(to source: DiffChatMessage) -> Bool {
        message.text == source.message.text
            && message.type == source.message.type
            && message.command == source.message.command
            && message.arguments == source.message.arguments
            && message.parentMessageId == source.message.parentMessageId
            && message.showReplyInChannel == source.message.showReplyInChannel
            && message.replyCount == source.message.replyCount
            && message.extraData == source.message.extraData
            && message.quotedMessage == source.message.quotedMessage
            && message.isShadowed == source.message.isShadowed
            && message.reactionCounts.count == source.message.reactionCounts.count
            && message.reactionScores.count == source.message.reactionScores.count
            && message.threadParticipants.count == source.message.threadParticipants.count
            && message.attachmentCounts.count == source.message.attachmentCounts.count
            && message.giphyAttachments == source.message.giphyAttachments
            && message.localState == source.message.localState
            && message.isFlaggedByCurrentUser == source.message.isFlaggedByCurrentUser
            && message.readBy == source.message.readBy
            && message.imageAttachments.map(\.uploadingState) == source.message.imageAttachments.map(\.uploadingState)
            && message.videoAttachments.map(\.uploadingState) == source.message.videoAttachments.map(\.uploadingState)
            && message.fileAttachments.map(\.uploadingState) == source.message.fileAttachments.map(\.uploadingState)
            && message.audioAttachments.map(\.uploadingState) == source.message.audioAttachments.map(\.uploadingState)
            && message.linkAttachments.map(\.uploadingState) == source.message.linkAttachments.map(\.uploadingState)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.message.id == rhs.message.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(message.id)
    }
}
