//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit.UIImage

public extension _UIConfig {
    struct MessageListUI {
        public var messageListVC: _ChatMessageListVC<ExtraData>.Type = _ChatMessageListVC<ExtraData>.self

        internal var defaultMessageCell: _СhatMessageCollectionViewCell<ExtraData>.Type =
            _СhatMessageCollectionViewCell<ExtraData>.self

        internal var collectionView: ChatMessageListCollectionView.Type = ChatMessageListCollectionView.self
        internal var collectionLayout: ChatMessageListCollectionViewLayout.Type = ChatMessageListCollectionViewLayout.self
        internal var channelNamer: ChatChannelNamer<ExtraData> = DefaultChatChannelNamer()
        internal var messageContentView: _ChatMessageContentView<ExtraData>.Type = _ChatMessageContentView<ExtraData>.self
        internal var messageContentSubviews = MessageContentViewSubviews()
        internal var messageActionsSubviews = MessageActionsSubviews()
        internal var messageReactions = MessageReactions()
    }
    
    struct MessageActionsSubviews {
        internal var actionsView: _ChatMessageActionsView<ExtraData>.Type =
            _ChatMessageActionsView<ExtraData>.self
        internal var actionButton: _ChatMessageActionsView<ExtraData>.ActionButton.Type =
            _ChatMessageActionsView<ExtraData>.ActionButton.self
    }
    
    struct MessageReactions {
        internal var reactionsBubbleView: _ChatMessageReactionsBubbleView<ExtraData>.Type =
            _ChatMessageDefaultReactionsBubbleView<ExtraData>.self
        internal var reactionsView: _ChatMessageReactionsView<ExtraData>.Type = _ChatMessageReactionsView<ExtraData>.self
        internal var reactionItemView: _ChatMessageReactionsView<ExtraData>.ItemView.Type =
            _ChatMessageReactionsView<ExtraData>.ItemView.self
    }
    
    struct MessageContentViewSubviews {
        internal var authorAvatarView: ChatAvatarView.Type = ChatAvatarView.self
        internal var bubbleView: _ChatMessageBubbleView<ExtraData>.Type = _ChatMessageBubbleView<ExtraData>.self
        internal var metadataView: _ChatMessageMetadataView<ExtraData>.Type = _ChatMessageMetadataView<ExtraData>.self
        internal var quotedMessageBubbleView: _ChatMessageQuoteBubbleView<ExtraData>.Type = _ChatMessageQuoteBubbleView.self
        internal var attachmentSubviews = MessageAttachmentViewSubviews()
        internal var onlyVisibleForCurrentUserIndicator: ChatMessageOnlyVisibleForCurrentUserIndicator<ExtraData>.Type =
            ChatMessageOnlyVisibleForCurrentUserIndicator<ExtraData>.self
        internal var threadArrowView: _ChatMessageThreadArrowView<ExtraData>.Type = _ChatMessageThreadArrowView<ExtraData>.self
        internal var threadInfoView: _ChatMessageThreadInfoView<ExtraData>.Type = _ChatMessageThreadInfoView<ExtraData>.self
        internal var threadParticipantAvatarView: ChatAvatarView.Type = ChatAvatarView.self
        internal var errorIndicator: _ChatMessageErrorIndicator<ExtraData>.Type = _ChatMessageErrorIndicator<ExtraData>.self
        internal var linkPreviewView: _ChatMessageLinkPreviewView<ExtraData>.Type = _ChatMessageLinkPreviewView<ExtraData>.self
    }
    
    struct MessageAttachmentViewSubviews {
        internal var loadingIndicator: _ChatLoadingIndicator<ExtraData>.Type = _ChatLoadingIndicator<ExtraData>.self
        internal var attachmentsView: _ChatMessageAttachmentsView<ExtraData>.Type = _ChatMessageAttachmentsView<ExtraData>.self
        // Files
        internal var fileAttachmentListView: _ChatMessageFileAttachmentListView<ExtraData>
            .Type = _ChatMessageFileAttachmentListView<ExtraData>.self
        internal var fileAttachmentItemView: _ChatMessageFileAttachmentListView<ExtraData>.ItemView.Type =
            _ChatMessageFileAttachmentListView<ExtraData>.ItemView.self
        // Images
        internal var imageGallery: _ChatMessageImageGallery<ExtraData>.Type = _ChatMessageImageGallery<ExtraData>.self
        internal var imageGalleryItem: _ChatMessageImageGallery<ExtraData>.ImagePreview.Type =
            _ChatMessageImageGallery<ExtraData>.ImagePreview.self
        internal var imageGalleryItemUploadingOverlay: _ChatMessageImageGallery<ExtraData>.UploadingOverlay.Type =
            _ChatMessageImageGallery<ExtraData>.UploadingOverlay.self
        // Interactive attachments
        internal var interactiveAttachmentView: _ChatMessageInteractiveAttachmentView<ExtraData>.Type =
            _ChatMessageInteractiveAttachmentView<ExtraData>.self
        internal var interactiveAttachmentActionButton: _ChatMessageInteractiveAttachmentView<ExtraData>.ActionButton.Type =
            _ChatMessageInteractiveAttachmentView<ExtraData>.ActionButton.self
        // Giphy
        internal var giphyAttachmentView: _ChatMessageGiphyView<ExtraData>.Type =
            _ChatMessageGiphyView<ExtraData>.self
        internal var giphyBadgeView: _ChatMessageGiphyView<ExtraData>.GiphyBadge.Type = _ChatMessageGiphyView<ExtraData>.GiphyBadge
            .self
    }
}
