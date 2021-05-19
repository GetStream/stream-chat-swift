//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias Components = _Components<NoExtraData>

public struct _Components<ExtraData: ExtraDataTypes> {
    /// The view used as a navigation bar title view for some view controllers.
    public var navigationTitleView: TitleContainerView.Type = TitleContainerView.self

    /// A button used for creating new channels.
    public var createChannelButton: UIButton.Type = CreateChatChannelButton.self

    /// A view used as an online activity indicator (online/offline).
    public var onlineIndicatorView: (UIView & MaskProviding).Type = ChatOnlineIndicatorView.self

    /// A view that displays the avatar image. By default a circular image.
    public var avatarView: ChatAvatarView.Type = ChatAvatarView.self

    /// An avatar view with an online indicator.
    public var presenceAvatarView: _ChatPresenceAvatarView<ExtraData>.Type = _ChatPresenceAvatarView<ExtraData>.self

    /// A `UIView` subclass which serves as container for `typingIndicator` and `UILabel` describing who is currently typing
    public var typingIndicatorView: _TypingIndicatorView<ExtraData>.Type = _TypingIndicatorView<ExtraData>.self
    
    /// A `UIView` subclass with animated 3 dots for indicating that user is typing.
    public var typingAnimationView: TypingAnimationView.Type = TypingAnimationView.self

    /// A view for inputting text with placeholder support.
    public var inputTextView: InputTextView.Type = InputTextView.self

    /// A view that displays the command name and icon.
    public var commandLabelView: CommandLabelView.Type = CommandLabelView.self

    /// A view to input content of a message.
    public var inputMessageView: _InputChatMessageView<ExtraData>.Type = _InputChatMessageView<ExtraData>.self

    /// A view that displays a quoted message.
    public var quotedMessageView: _QuotedChatMessageView<ExtraData>.Type = _QuotedChatMessageView<ExtraData>.self

    /// A button used for sending a message, or any type of content.
    public var sendButton: UIButton.Type = SendButton.self

    /// A button for confirming actions.
    public var confirmButton: UIButton.Type = ConfirmButton.self

    /// A button for opening attachments.
    public var attachmentButton: UIButton.Type = AttachmentButton.self

    /// A view used as a fallback preview view for attachments that don't confirm to `AttachmentPreviewProvider`
    public var attachmentPreviewViewPlaceholder: UIView.Type = AttachmentPlaceholderView.self

    /// A button for opening commands.
    public var commandsButton: UIButton.Type = CommandButton.self

    /// A button for shrinking the input view to allow more space for other actions.
    public var shrinkInputButton: UIButton.Type = ShrinkInputButton.self

    /// A button for closing, dismissing or clearing information.
    public var closeButton: UIButton.Type = CloseButton.self

    /// A view to check/uncheck an option.
    public var checkmarkControl: CheckboxControl.Type = CheckboxControl.self

    /// An object responsible for message layout options calculations in `ChatMessageListVC/ChatThreadVC`.
    public var messageLayoutOptionsResolver: _ChatMessageLayoutOptionsResolver<ExtraData> = .init()

    // MARK: - Message list components

    /// The view used to display content of the message, i.e. in the channel detail message list.
    public var messageContentView: _ChatMessageContentView<ExtraData>.Type = _ChatMessageContentView<ExtraData>.self

    /// The injector used to inject gallery attachment views.
    public var galleryAttachmentInjector: _AttachmentViewInjector<ExtraData>.Type = _GalleryAttachmentViewInjector<ExtraData>.self
    /// The injector used to inject link attachment views.
    public var linkAttachmentInjector: _AttachmentViewInjector<ExtraData>.Type = _LinkAttachmentViewInjector<ExtraData>.self
    /// The injector used for injecting giphy attachment views
    public var giphyAttachmentInjector: _AttachmentViewInjector<ExtraData>.Type = _GiphyAttachmentViewInjector<ExtraData>.self
    /// The injector used for injecting file attachment views
    public var filesAttachmentInjector: _FilesAttachmentViewInjector<ExtraData>.Type = _FilesAttachmentViewInjector<ExtraData>.self

    // MARK: - Channel list components

    /// The logic to generate a name for the given channel.
    public var channelNamer: ChatChannelNamer<ExtraData> = DefaultChatChannelNamer()

    /// The collection view layout of the channel list.
    public var channelListLayout: UICollectionViewLayout.Type = ListCollectionViewLayout.self

    /// The `UICollectionViewCell` subclass that shows channel information.
    public var channelCell: _ChatChannelListCollectionViewCell<ExtraData>.Type =
        _ChatChannelListCollectionViewCell<ExtraData>.self

    /// The channel cell separator in the channel list.
    public var channelCellSeparator: UICollectionReusableView.Type = CellSeparatorReusableView.self

    /// The view in the channel cell that shows channel actions on swipe.
    public var channelActionsView: _SwipeableView<ExtraData>.Type =
        _SwipeableView<ExtraData>.self
    
    /// The view that shows channel information.
    public var channelContentView: _ChatChannelListItemView<ExtraData>.Type = _ChatChannelListItemView<ExtraData>.self

    /// The view that shows a user avatar including an indicator of the user presence (online/offline).
    public var channelAvatarView: _ChatChannelAvatarView<ExtraData>.Type = _ChatChannelAvatarView.self

    /// The view that shows a number of unread messages in channel.
    public var channelUnreadCountView: ChatChannelUnreadCountView.Type = ChatChannelUnreadCountView.self

    /// The view that shows a read/unread status of the last message in channel.
    public var channelReadStatusView: ChatChannelReadStatusCheckmarkView.Type =
        ChatChannelReadStatusCheckmarkView.self

    // MARK: - Message composer components

    /// The view controller used to compose a message.
    public var messageComposerVC: _ComposerVC<ExtraData>.Type =
        _ComposerVC<ExtraData>.self

    /// The view that shows the message when it's being composed.
    public var messageComposerView: _ComposerView<ExtraData>.Type =
        _ComposerView<ExtraData>.self

    /// A view controller that handles the attachments.
    public var messageComposerAttachmentsVC: _AttachmentsPreviewVC<ExtraData>.Type =
        _AttachmentsPreviewVC<ExtraData>.self

    /// A view that holds the attachment views and provide extra functionality over them.
    public var messageComposerAttachmentCell: AttachmentPreviewContainer.Type = AttachmentPreviewContainer.self

    /// A view that displays the document attachment.
    public var messageComposerFileAttachmentView: FileAttachmentView.Type = FileAttachmentView.self

    /// A view that displays the image attachment.
    public var messageComposerImageAttachmentView: ImageAttachmentView.Type = ImageAttachmentView.self

    /// A view controller that shows suggestions of commands or mentions.
    public var suggestionsVC: _ChatSuggestionsViewController<ExtraData>.Type =
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

    // MARK: - Current user components

    /// The view that shows current user avatar.
    public var currentUserAvatarView: _CurrentChatUserAvatarView<ExtraData>.Type =
        _CurrentChatUserAvatarView<ExtraData>.self

    public var messageList = MessageListUI()
    public var navigation = Navigation()

    public init() {}
}

// MARK: - Components + Default

private var defaults: [String: Any] = [:]

public extension _Components {
    static var `default`: Self {
        get {
            let key = String(describing: ExtraData.self)
            if let existing = defaults[key] as? Self {
                return existing
            } else {
                let config = Self()
                defaults[key] = config
                return config
            }
        }
        set {
            let key = String(describing: ExtraData.self)
            defaults[key] = newValue
        }
    }
}
