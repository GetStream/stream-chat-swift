//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit.UIImage

public extension _UIConfig {
    struct MessageListUI {
        public var messageListVC: _ChatMessageListVC<ExtraData>.Type = _ChatMessageListVC<ExtraData>.self
        public var incomingMessageCell: _СhatMessageCollectionViewCell<ExtraData>.Type =
            СhatIncomingMessageCollectionViewCell<ExtraData>.self
        public var outgoingMessageCell: _СhatMessageCollectionViewCell<ExtraData>.Type =
            СhatOutgoingMessageCollectionViewCell<ExtraData>.self
        
        public var incomingMessageAttachmentCell: _СhatMessageCollectionViewCell<ExtraData>.Type =
            СhatIncomingMessageAttachmentCollectionViewCell<ExtraData>.self
        public var outgoingMessageAttachmentCell: _СhatMessageCollectionViewCell<ExtraData>.Type =
            СhatOutgoingMessageAttachmentCollectionViewCell<ExtraData>.self

        public var collectionView: ChatMessageListCollectionView.Type = ChatMessageListCollectionView.self
        public var collectionLayout: ChatMessageListCollectionViewLayout.Type = ChatMessageListCollectionViewLayout.self
        public var channelNamer: ChatChannelNamer<ExtraData> = DefaultChatChannelNamer()
        public var messageContentView: _ChatMessageContentView<ExtraData>.Type = _ChatMessageContentView<ExtraData>.self
        public var messageAttachmentContentView: _ChatMessageAttachmentContentView<ExtraData>
            .Type = _ChatMessageAttachmentContentView<ExtraData>.self
        public var messageContentSubviews = MessageContentViewSubviews()
        public var messageActionsSubviews = MessageActionsSubviews()
        public var messageReactions = MessageReactions()
    }

    struct MessageActionsSubviews {
        public var actionsView: _ChatMessageActionsView<ExtraData>.Type =
            _ChatMessageActionsView<ExtraData>.self
        public var actionButton: _ChatMessageActionsView<ExtraData>.ActionButton.Type =
            _ChatMessageActionsView<ExtraData>.ActionButton.self
    }

    struct MessageReactions {
        public var reactionsBubbleView: _ChatMessageReactionsBubbleView<ExtraData>.Type =
            _ChatMessageDefaultReactionsBubbleView<ExtraData>.self
        public var reactionsView: _ChatMessageReactionsView<ExtraData>.Type = _ChatMessageReactionsView<ExtraData>.self
        public var reactionItemView: _ChatMessageReactionsView<ExtraData>.ItemView.Type =
            _ChatMessageReactionsView<ExtraData>.ItemView.self
    }

    struct MessageContentViewSubviews {
        public var authorAvatarView: ChatAvatarView.Type = ChatAvatarView.self
        public var bubbleView: _ChatMessageBubbleView<ExtraData>.Type = _ChatMessageBubbleView<ExtraData>.self
        public var attachmentBubbleView: _ChatMessageAttachmentBubbleView<ExtraData>
            .Type = _ChatMessageAttachmentBubbleView<ExtraData>.self
        public var metadataView: _ChatMessageMetadataView<ExtraData>.Type = _ChatMessageMetadataView<ExtraData>.self
        public var quotedMessageBubbleView: _ChatMessageQuoteBubbleView<ExtraData>.Type = _ChatMessageQuoteBubbleView.self
        public var attachmentSubviews = MessageAttachmentViewSubviews()
        public var onlyVisibleForCurrentUserIndicator: ChatMessageOnlyVisibleForCurrentUserIndicator<ExtraData>.Type =
            ChatMessageOnlyVisibleForCurrentUserIndicator<ExtraData>.self
        public var threadArrowView: _ChatMessageThreadArrowView<ExtraData>.Type = _ChatMessageThreadArrowView<ExtraData>.self
        public var threadInfoView: _ChatMessageThreadInfoView<ExtraData>.Type = _ChatMessageThreadInfoView<ExtraData>.self
        public var threadParticipantAvatarView: ChatAvatarView.Type = ChatAvatarView.self
        public var errorIndicator: _ChatMessageErrorIndicator<ExtraData>.Type = _ChatMessageErrorIndicator<ExtraData>.self
        public var linkPreviewView: _ChatMessageLinkPreviewView<ExtraData>.Type = _ChatMessageLinkPreviewView<ExtraData>.self
    }

    struct MessageAttachmentViewSubviews {
        public var loadingIndicator: _ChatLoadingIndicator<ExtraData>.Type = _ChatLoadingIndicator<ExtraData>.self
        public var attachmentsView: _ChatMessageAttachmentsView<ExtraData>.Type = _ChatMessageAttachmentsView<ExtraData>.self
        // Files
        public var fileAttachmentListView: _ChatMessageFileAttachmentListView<ExtraData>
            .Type = _ChatMessageFileAttachmentListView<ExtraData>.self
        public var fileAttachmentItemView: _ChatMessageFileAttachmentListView<ExtraData>.ItemView.Type =
            _ChatMessageFileAttachmentListView<ExtraData>.ItemView.self
        // Images
        public var imageGallery: _ChatMessageImageGallery<ExtraData>.Type = _ChatMessageImageGallery<ExtraData>.self
        public var imageGalleryItem: _ChatMessageImageGallery<ExtraData>.ImagePreview.Type =
            _ChatMessageImageGallery<ExtraData>.ImagePreview.self
        public var imageGalleryItemUploadingOverlay: _ChatMessageImageGallery<ExtraData>.UploadingOverlay.Type =
            _ChatMessageImageGallery<ExtraData>.UploadingOverlay.self
        // Interactive attachments
        public var interactiveAttachmentView: _ChatMessageInteractiveAttachmentView<ExtraData>.Type =
            _ChatMessageInteractiveAttachmentView<ExtraData>.self
        public var interactiveAttachmentActionButton: _ChatMessageInteractiveAttachmentView<ExtraData>.ActionButton.Type =
            _ChatMessageInteractiveAttachmentView<ExtraData>.ActionButton.self
        // Giphy
        public var giphyAttachmentView: _ChatMessageGiphyView<ExtraData>.Type =
            _ChatMessageGiphyView<ExtraData>.self
        public var giphyBadgeView: _ChatMessageGiphyView<ExtraData>.GiphyBadge.Type = _ChatMessageGiphyView<ExtraData>.GiphyBadge
            .self
    }
}
