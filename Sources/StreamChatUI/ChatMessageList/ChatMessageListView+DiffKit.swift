//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
        let isAttachmentsEqual: (ChatMessage, ChatMessage) -> Bool = {
            $0.giphyAttachments.map(\.previewURL) == $1.giphyAttachments.map(\.previewURL)
                && $0.imageAttachments.map(\.uploadingState) == $1.imageAttachments.map(\.uploadingState)
                && $0.videoAttachments.map(\.uploadingState) == $1.videoAttachments.map(\.uploadingState)
                && $0.fileAttachments.map(\.uploadingState) == $1.fileAttachments.map(\.uploadingState)
                && $0.audioAttachments.map(\.uploadingState) == $1.audioAttachments.map(\.uploadingState)
                && $0.linkAttachments.map(\.uploadingState) == $1.linkAttachments.map(\.uploadingState)
        }

        let isQuotedMessageEqual: (ChatMessage?, ChatMessage?) -> Bool = {
            if let quotedMessage = $0, let sourceQuotedMessage = $1 {
                return quotedMessage.id == sourceQuotedMessage.id
                    && quotedMessage.text == sourceQuotedMessage.text
                    && isAttachmentsEqual(quotedMessage, sourceQuotedMessage)
            }

            return $0?.id == $1?.id
        }

        return id == source.id
            && text == source.text
            && type == source.type
            && command == source.command
            && arguments == source.arguments
            && parentMessageId == source.parentMessageId
            && showReplyInChannel == source.showReplyInChannel
            && replyCount == source.replyCount
            && extraData == source.extraData
            && isShadowed == source.isShadowed
            && currentUserReactions.count == source.currentUserReactions.count
            && reactionCounts == source.reactionCounts
            && reactionScores == source.reactionScores
            && threadParticipants.count == source.threadParticipants.count
            && localState == source.localState
            && isFlaggedByCurrentUser == source.isFlaggedByCurrentUser
            && readBy.count == source.readBy.count
            && isQuotedMessageEqual(quotedMessage, source.quotedMessage)
            && isAttachmentsEqual(self, source)
    }
}
