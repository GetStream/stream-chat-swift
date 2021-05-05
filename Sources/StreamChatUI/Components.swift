//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias Components = _Components<NoExtraData>

public struct _Components<ExtraData: ExtraDataTypes> {
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
    public var commandLabelView: _CommandLabelView<ExtraData>.Type = _CommandLabelView<ExtraData>.self

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

    /// A button for opening commands.
    public var commandsButton: UIButton.Type = CommandButton.self

    /// A button for shrinking the input view to allow more space for other actions.
    public var shrinkInputButton: UIButton.Type = ShrinkInputButton.self

    /// A button for closing, dismissing or clearing information.
    public var closeButton: UIButton.Type = ShrinkInputButton.self

    /// A view to check/uncheck an option.
    public var checkmarkControl: CheckboxControl.Type = CheckboxControl.self

    /// An object responsible for message layout options calculations in `ChatMessageListVC/ChatThreadVC`.
    public var messageLayoutOptionsResolver: _ChatMessageLayoutOptionsResolver<ExtraData> = .init()

    // MARK: - Message list components

    /// The view used to display content of the message, i.e. in the channel detail message list.
    public var messageContentView: _ChatMessageContentView<ExtraData>.Type = _ChatMessageContentView<ExtraData>.self

    /// The injector used to inject gallery attachment views
    public var galleryAttachmentInjector: _AttachmentViewInjector<ExtraData>.Type = _GalleryAttachmentViewInjector<ExtraData>.self

    public var channelList = ChannelList()
    public var messageList = MessageListUI()
    public var messageComposer = MessageComposer()
    public var currentUser = CurrentUser()
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
