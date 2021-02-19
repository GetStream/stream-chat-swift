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
        internal var documentAttachmentsView: _ChatMessageComposerDocumentAttachmentsView<ExtraData>.Type =
            _ChatMessageComposerDocumentAttachmentsView<ExtraData>.self
        /// Button used in Composer used for sending messages.
        internal var sendButton: UIButton.Type = _ChatMessageSendButton<ExtraData>.self
        /// Button used in Composer used for confirming editing messages.
        internal var editButton: UIButton.Type = _ChatMessageConfirmEditButton<ExtraData>.self

        /// A view that displays a collection of image attachments
        internal var imageAttachmentsView: _ChatMessageComposerImageAttachmentsView<ExtraData>.Type =
            _ChatMessageComposerImageAttachmentsView<ExtraData>.self
        /// The collection view of image attachments.
        internal var imageAttachmentsCollectionView: UICollectionView.Type = UICollectionView.self
        /// The collection view layout of the image attachments collection view.
        internal var imageAttachmentsCollectionViewLayout: UICollectionViewFlowLayout.Type =
            UICollectionViewFlowLayout.self
        /// A view that displays the image attachment.
        internal var imageAttachmentCellView: _ChatMessageComposerImageAttachmentView<ExtraData>.Type =
            _ChatMessageComposerImageAttachmentView<ExtraData>.self
        /// The view cell that displays the image attachment.
        internal var imageAttachmentCollectionViewCell: _ChatMessageComposerImageAttachmentCollectionViewCell<ExtraData>.Type =
            _ChatMessageComposerImageAttachmentCollectionViewCell<ExtraData>.self

        /// Buttons used in the left side of the composer. Corresponds to attachment and actions buttons.
        internal var composerButton: UIButton.Type = UIButton.self
        internal var textView: _ChatMessageComposerInputTextView<ExtraData>.Type = _ChatMessageComposerInputTextView<ExtraData>.self

        internal var checkmarkControl: _ChatMessageComposerCheckmarkControl<ExtraData>.Type =
            _ChatMessageComposerCheckmarkControl<ExtraData>.self
        internal var slashCommandView: _ChatMessageInputSlashCommandView<ExtraData>
            .Type = _ChatMessageInputSlashCommandView<ExtraData>.self

        /// A view controller that shows suggestions of commands or mentions.
        internal var suggestionsViewController: _ChatMessageComposerSuggestionsViewController<ExtraData>.Type =
            _ChatMessageComposerSuggestionsViewController<ExtraData>.self
        /// The collection view of the suggestions view controller.
        internal var suggestionsCollectionView: _ChatMessageComposerSuggestionsCollectionView.Type =
            _ChatMessageComposerSuggestionsCollectionView<ExtraData>.self
        /// A view cell that displays the the suggested mention.
        internal var suggestionsMentionCollectionViewCell: _ChatMessageComposerMentionCollectionViewCell<ExtraData>.Type =
            _ChatMessageComposerMentionCollectionViewCell<ExtraData>.self
        /// A view cell that displays the suggested command.
        internal var suggestionsCommandCollectionViewCell: _ChatMessageComposerCommandCollectionViewCell<ExtraData>.Type =
            _ChatMessageComposerCommandCollectionViewCell<ExtraData>.self
        /// A type for view embed in cell while tagging users with @ symbol in composer.
        internal var suggestionsMentionCellView: _ChatMessageComposerMentionCellView<ExtraData>.Type =
            _ChatMessageComposerMentionCellView<ExtraData>.self
        /// A view that displays the command name, image and arguments.
        internal var suggestionsCommandCellView: _ChatMessageComposerCommandCellView<ExtraData>.Type =
            _ChatMessageComposerCommandCellView<ExtraData>.self
        /// The collection view layout of the suggestions collection view.
        internal var suggestionsCollectionViewLayout: UICollectionViewLayout.Type =
            ChatMessageComposerSuggestionsCollectionViewLayout.self
        /// The header reusable view of the suggestion collection view.
        internal var suggestionsHeaderReusableView: UICollectionReusableView.Type =
            _ChatMessageComposerSuggestionsCommandsReusableView<ExtraData>.self
        /// The header view of the suggestion collection view.
        internal var suggestionsHeaderView: _ChatMessageComposerSuggestionsCommandsHeaderView<ExtraData>.Type =
            _ChatMessageComposerSuggestionsCommandsHeaderView<ExtraData>.self
        /// A type for the view used as avatar when picking users to mention.
        internal var mentionAvatarView: _ChatUserAvatarView<ExtraData>.Type = _ChatUserAvatarView<ExtraData>.self
    }
}
