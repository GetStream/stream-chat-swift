//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit.UIImage

public extension _Components {
    struct MessageComposer {
        public var messageComposerViewController: _ComposerVC<ExtraData>.Type =
            _ComposerVC<ExtraData>.self
        public var messageComposerView: _ComposerView<ExtraData>.Type =
            _ComposerView<ExtraData>.self

        /// A view controller that handles the attachments.
        public var attachmentsViewController: _AttachmentsPreviewVC<ExtraData>.Type =
            _AttachmentsPreviewVC<ExtraData>.self
        /// A view that holds the attachment views and provide extra functionality over them.
        public var attachmentCell: AttachmentPreviewContainer.Type = AttachmentPreviewContainer.self
        /// A view that displays the document attachment.
        public var fileAttachmentView: FileAttachmentView.Type = FileAttachmentView.self
        /// A view that displays the image attachment.
        public var imageAttachmentView: ImageAttachmentView.Type = ImageAttachmentView.self

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
