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
        text == source.text
            && type == source.type
            && command == source.command
            && arguments == source.arguments
            && parentMessageId == source.parentMessageId
            && showReplyInChannel == source.showReplyInChannel
            && replyCount == source.replyCount
            && extraData == source.extraData
            && quotedMessage == source.quotedMessage
            && isShadowed == source.isShadowed
            && reactionCounts.count == source.reactionCounts.count
            && reactionScores.count == source.reactionScores.count
            && threadParticipants.count == source.threadParticipants.count
            && localState == source.localState
            && isFlaggedByCurrentUser == source.isFlaggedByCurrentUser
            && readBy.count == source.readBy.count
            && giphyAttachments.map(\.previewURL) == source.giphyAttachments.map(\.previewURL)
            && imageAttachments.map(\.uploadingState) == source.imageAttachments.map(\.uploadingState)
            && videoAttachments.map(\.uploadingState) == source.videoAttachments.map(\.uploadingState)
            && fileAttachments.map(\.uploadingState) == source.fileAttachments.map(\.uploadingState)
            && audioAttachments.map(\.uploadingState) == source.audioAttachments.map(\.uploadingState)
            && linkAttachments.map(\.uploadingState) == source.linkAttachments.map(\.uploadingState)
    }
}
