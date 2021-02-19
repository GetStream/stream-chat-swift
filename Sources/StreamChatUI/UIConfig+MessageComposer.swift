//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit.UIImage

internal extension _UIConfig {
    struct MessageComposer {
        internal var messageComposerViewController: _ChatMessageComposerVC<ExtraData>.Type =
            _ChatMessageComposerVC<ExtraData>.self
        internal var messageComposerView: _ChatMessageComposerView<ExtraData>.Type =
            _ChatMessageComposerView<ExtraData>.self
        internal var messageInputView: _ChatMessageComposerInputContainerView<ExtraData>
            .Type = _ChatMessageComposerInputContainerView<ExtraData>.self
        internal var documentAttachmentView: _ChatMessageComposerDocumentAttachmentView<ExtraData>.Type =
            _ChatMessageComposerDocumentAttachmentView<ExtraData>.self
        internal var documentAttachmentsFlowLayout: ChatMessageComposerDocumentAttachmentsCollectionViewLayout.Type =
            ChatMessageComposerDocumentAttachmentsCollectionViewLayout.self
        internal var imageAttachmentsView: _ChatMessageComposerImageAttachmentsView<ExtraData>.Type =
            _ChatMessageComposerImageAttachmentsView<ExtraData>.self
        internal var documentAttachmentsView: _ChatMessageComposerDocumentAttachmentsView<ExtraData>.Type =
            _ChatMessageComposerDocumentAttachmentsView<ExtraData>.self
        internal var sendButton: _ChatMessageComposerSendButton<ExtraData>.Type = _ChatMessageComposerSendButton<ExtraData>.self
        internal var composerButton: _ChatSquareButton<ExtraData>.Type = _ChatSquareButton<ExtraData>.self
        internal var textView: _ChatMessageComposerInputTextView<ExtraData>.Type = _ChatMessageComposerInputTextView<ExtraData>.self
        internal var quotedMessageView: _ChatMessageComposerQuoteBubbleView<ExtraData>.Type = _ChatMessageComposerQuoteBubbleView
            .self
        internal var quotedMessageAvatarView: ChatAvatarView.Type = ChatAvatarView.self
        internal var checkmarkControl: _ChatMessageComposerCheckmarkControl<ExtraData>.Type =
            _ChatMessageComposerCheckmarkControl<ExtraData>.self
        internal var slashCommandView: _ChatMessageInputSlashCommandView<ExtraData>
            .Type = _ChatMessageInputSlashCommandView<ExtraData>.self
        internal var suggestionsViewController: _ChatMessageComposerSuggestionsViewController<ExtraData>.Type =
            _ChatMessageComposerSuggestionsViewController<ExtraData>.self
        internal var suggestionsCollectionView: _ChatMessageComposerSuggestionsCollectionView.Type =
            _ChatMessageComposerSuggestionsCollectionView<ExtraData>.self
        internal var suggestionsMentionCollectionViewCell: _ChatMessageComposerMentionCollectionViewCell<ExtraData>.Type =
            _ChatMessageComposerMentionCollectionViewCell<ExtraData>.self
        /// A view cell that displays the command name, image and arguments.
        internal var suggestionsCommandCollectionViewCell: _ChatMessageComposerCommandCollectionViewCell<ExtraData>.Type =
            _ChatMessageComposerCommandCollectionViewCell<ExtraData>.self
        /// A type for view embed in cell while tagging users with @ symbol in composer.
        internal var suggestionsMentionCellView: _ChatMessageComposerMentionCellView<ExtraData>.Type =
            _ChatMessageComposerMentionCellView<ExtraData>.self
        /// A view that displays the command name, image and arguments.
        internal var suggestionsCommandCellView: _ChatMessageComposerCommandCellView<ExtraData>.Type =
            _ChatMessageComposerCommandCellView<ExtraData>.self
        internal var suggestionsCollectionViewLayout: ChatMessageComposerSuggestionsCollectionViewLayout.Type =
            ChatMessageComposerSuggestionsCollectionViewLayout.self
        internal var suggestionsHeaderReusableView: _ChatMessageComposerSuggestionsCommandsReusableView<ExtraData>.Type =
            _ChatMessageComposerSuggestionsCommandsReusableView.self
        internal var suggestionsHeaderView: _ChatMessageComposerSuggestionsCommandsHeaderView<ExtraData>.Type =
            _ChatMessageComposerSuggestionsCommandsHeaderView.self
        /// A type for the view used as avatar when picking users to mention.
        internal var mentionAvatarView: _ChatChannelAvatarView<ExtraData>
            .Type = _ChatChannelAvatarView<ExtraData>.self
    }
}
