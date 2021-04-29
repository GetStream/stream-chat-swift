//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit.UIImage

public extension _Components {
    struct MessageComposer {
        public var messageComposerViewController: _ChatMessageComposerVC<ExtraData>.Type =
            _ChatMessageComposerVC<ExtraData>.self
        public var messageComposerView: _ChatMessageComposerView<ExtraData>.Type =
            _ChatMessageComposerView<ExtraData>.self

        public var documentAttachmentView: _ChatMessageComposerDocumentAttachmentView<ExtraData>.Type =
            _ChatMessageComposerDocumentAttachmentView<ExtraData>.self
        public var documentAttachmentsFlowLayout: ChatMessageComposerDocumentAttachmentsCollectionViewLayout.Type =
            ChatMessageComposerDocumentAttachmentsCollectionViewLayout.self
        public var documentAttachmentsView: _ChatMessageComposerDocumentAttachmentsView<ExtraData>.Type =
            _ChatMessageComposerDocumentAttachmentsView<ExtraData>.self
        /// Button used in Composer used for confirming editing messages.
        public var editButton: UIButton.Type = ChatMessageConfirmEditButton.self

        /// A view that displays a collection of image attachments
        public var imageAttachmentsView: _ChatMessageComposerImageAttachmentsView<ExtraData>.Type =
            _ChatMessageComposerImageAttachmentsView<ExtraData>.self
        /// The collection view of image attachments.
        public var imageAttachmentsCollectionView: UICollectionView.Type = UICollectionView.self
        /// The collection view layout of the image attachments collection view.
        public var imageAttachmentsCollectionViewLayout: UICollectionViewFlowLayout.Type =
            UICollectionViewFlowLayout.self
        /// A view that displays the image attachment.
        public var imageAttachmentCellView: ChatMessageComposerImageAttachmentView.Type =
            ChatMessageComposerImageAttachmentView.self
        /// The view cell that displays the image attachment.
        public var imageAttachmentCollectionViewCell: _ChatMessageComposerImageAttachmentCollectionViewCell<ExtraData>.Type =
            _ChatMessageComposerImageAttachmentCollectionViewCell<ExtraData>.self

        /// Buttons used in the left side of the composer. Corresponds to attachment and actions buttons.
        public var composerButton: UIButton.Type = UIButton.self

        public var checkmarkControl: ChatMessageComposerCheckmarkControl.Type =
            ChatMessageComposerCheckmarkControl.self

        /// A view controller that shows suggestions of commands or mentions.
        public var suggestionsViewController: _ChatSuggestionsViewController<ExtraData>.Type =
            _ChatSuggestionsViewController<ExtraData>.self
        /// The collection view of the suggestions view controller.
        public var suggestionsCollectionView: _ChatSuggestionsCollectionView<ExtraData>.Type =
            _ChatSuggestionsCollectionView<ExtraData>.self
        /// A view cell that displays the the suggested mention.
        public var suggestionsMentionCollectionViewCell: _ChatMentionSuggestionCollectionViewCell<ExtraData>.Type =
            _ChatMentionSuggestionCollectionViewCell<ExtraData>.self
        /// A view cell that displays the suggested command.
        public var suggestionsCommandCollectionViewCell: _ChatCommandSuggestionCollectionViewCell<ExtraData>.Type =
            _ChatCommandSuggestionCollectionViewCell<ExtraData>.self
        /// A type for view embed in cell while tagging users with @ symbol in composer.
        public var suggestionsMentionCellView: _ChatMentionSuggestionView<ExtraData>.Type =
            _ChatMentionSuggestionView<ExtraData>.self
        /// A view that displays the command name, image and arguments.
        public var suggestionsCommandCellView: ChatCommandSuggestionView.Type =
            ChatCommandSuggestionView.self
        /// The collection view layout of the suggestions collection view.
        public var suggestionsCollectionViewLayout: UICollectionViewLayout.Type =
            ChatSuggestionsCollectionViewLayout.self
        /// The header reusable view of the suggestion collection view.
        public var suggestionsHeaderReusableView: UICollectionReusableView.Type =
            _ChatSuggestionsCollectionReusableView<ExtraData>.self
        /// The header view of the suggestion collection view.
        public var suggestionsHeaderView: ChatSuggestionsHeaderView.Type =
            ChatSuggestionsHeaderView.self
        /// A type for the view used as avatar when picking users to mention.
        public var mentionAvatarView: _ChatUserAvatarView<ExtraData>.Type = _ChatUserAvatarView<ExtraData>.self
    }
}
