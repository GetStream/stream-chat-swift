//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit.UIImage

public extension _UIConfig {
    struct MessageComposer {
        public var messageComposerViewController: _ChatMessageComposerVC<ExtraData>.Type =
            _ChatMessageComposerVC<ExtraData>.self
        public var messageComposerView: _ChatMessageComposerView<ExtraData>.Type =
            _ChatMessageComposerView<ExtraData>.self
        public var messageInputView: _ChatMessageComposerInputContainerView<ExtraData>
            .Type = _ChatMessageComposerInputContainerView<ExtraData>.self
        public var documentAttachmentView: _ChatMessageComposerDocumentAttachmentView<ExtraData>.Type =
            _ChatMessageComposerDocumentAttachmentView<ExtraData>.self
        public var documentAttachmentsFlowLayout: ChatMessageComposerDocumentAttachmentsCollectionViewLayout.Type =
            ChatMessageComposerDocumentAttachmentsCollectionViewLayout.self
        public var imageAttachmentsView: _ChatMessageComposerImageAttachmentsView<ExtraData>.Type =
            _ChatMessageComposerImageAttachmentsView<ExtraData>.self
        public var documentAttachmentsView: _ChatMessageComposerDocumentAttachmentsView<ExtraData>.Type =
            _ChatMessageComposerDocumentAttachmentsView<ExtraData>.self
        public var sendButton: _ChatMessageComposerSendButton<ExtraData>.Type = _ChatMessageComposerSendButton<ExtraData>.self
        public var composerButton: _ChatSquareButton<ExtraData>.Type = _ChatSquareButton<ExtraData>.self
        public var textView: _ChatMessageComposerInputTextView<ExtraData>.Type = _ChatMessageComposerInputTextView<ExtraData>.self
        public var quotedMessageView: _ChatMessageComposerQuoteBubbleView<ExtraData>.Type = _ChatMessageComposerQuoteBubbleView.self
        public var quotedMessageAvatarView: ChatAvatarView.Type = ChatAvatarView.self
        public var checkmarkControl: _ChatMessageComposerCheckmarkControl<ExtraData>.Type =
            _ChatMessageComposerCheckmarkControl<ExtraData>.self
        public var slashCommandView: _ChatMessageInputSlashCommandView<ExtraData>
            .Type = _ChatMessageInputSlashCommandView<ExtraData>.self
        public var suggestionsViewController: _ChatMessageComposerSuggestionsViewController<ExtraData>.Type =
            _ChatMessageComposerSuggestionsViewController<ExtraData>.self
        public var suggestionsCollectionView: _ChatMessageComposerSuggestionsCollectionView.Type =
            _ChatMessageComposerSuggestionsCollectionView<ExtraData>.self
        public var suggestionsMentionCollectionViewCell: _ChatMessageComposerMentionCollectionViewCell<ExtraData>.Type =
            _ChatMessageComposerMentionCollectionViewCell<ExtraData>.self
        /// A view cell that displays the command name, image and arguments.
        public var suggestionsCommandCollectionViewCell: _ChatMessageComposerCommandCollectionViewCell<ExtraData>.Type =
            _ChatMessageComposerCommandCollectionViewCell<ExtraData>.self
        /// A type for view embed in cell while tagging users with @ symbol in composer.
        public var suggestionsMentionCellView: _ChatMessageComposerMentionCellView<ExtraData>.Type =
            _ChatMessageComposerMentionCellView<ExtraData>.self
        /// A view that displays the command name, image and arguments.
        public var suggestionsCommandCellView: _ChatMessageComposerCommandCellView<ExtraData>.Type =
            _ChatMessageComposerCommandCellView<ExtraData>.self
        public var suggestionsCollectionViewLayout: ChatMessageComposerSuggestionsCollectionViewLayout.Type =
            ChatMessageComposerSuggestionsCollectionViewLayout.self
        public var suggestionsHeaderReusableView: _ChatMessageComposerSuggestionsCommandsReusableView<ExtraData>.Type =
            _ChatMessageComposerSuggestionsCommandsReusableView.self
        public var suggestionsHeaderView: _ChatMessageComposerSuggestionsCommandsHeaderView<ExtraData>.Type =
            _ChatMessageComposerSuggestionsCommandsHeaderView.self
        /// A type for the view used as avatar when picking users to mention.
        public var mentionAvatarView: _ChatChannelAvatarView<ExtraData>
            .Type = _ChatChannelAvatarView<ExtraData>.self
    }
}
