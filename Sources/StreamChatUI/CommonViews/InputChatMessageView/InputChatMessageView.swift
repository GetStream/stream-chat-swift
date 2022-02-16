//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view to input content of a message.
open class InputChatMessageView: _View, ComponentsProvider, AppearanceProvider {
    /// The content of the view
    public struct Content {
        /// The message that is being quoted.
        var quotingMessage: ChatMessage?
        /// The command that the message produces.
        var command: Command?
    }

    /// The content of the view
    public var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// A button to send the message.
    public private(set) lazy var sendButton: UIButton = components
        .sendButton.init()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var emojiButton: UIButton = components
        .emojiButton.init()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var emptyView: UIView = {
        let view = UIView()
        view.frame = .zero
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    /// The main container stack view that layouts all the message input content views.
    public private(set) lazy var container = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    /// A view that displays the quoted message that the new message is replying.
    public private(set) lazy var quotedMessageView = components
        .quotedMessageView.init()
        .withoutAutoresizingMaskConstraints

    /// A view that displays the attachments of the new message.
    /// This is view from separate AttachmentsVC and will be injected by the ComposerVC.
    public private(set) lazy var attachmentsViewContainer = UIView()
        .withoutAutoresizingMaskConstraints

    /// The container stack view that layouts the command label, text view and the clean button.
    public private(set) lazy var inputTextContainer = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    /// The input text view to type a new message or command.
    public private(set) lazy var textView: InputTextView = components
        .inputTextView.init()
        .withoutAutoresizingMaskConstraints

    /// The command label that display the command info if a new command is being typed.
    public private(set) lazy var commandLabelView: CommandLabelView = components
        .commandLabelView.init()
        .withoutAutoresizingMaskConstraints

    /// A button to clear the current typing information.
    public private(set) lazy var clearButton: UIButton = components
        .closeButton.init()
        .withoutAutoresizingMaskConstraints

    override open func setUpAppearance() {
        super.setUpAppearance()

        let closeTransparentImage = appearance.images.closeCircleTransparent
            .tinted(with: appearance.colorPalette.inactiveTint)
        clearButton.setImage(closeTransparentImage, for: .normal)

        container.clipsToBounds = true
        container.layer.cornerRadius = 19
        container.layer.borderWidth = 1
        container.layer.borderColor = appearance.colorPalette.border.cgColor
    }
    
    override open func setUpLayout() {
        addSubview(container)
        container.pin(to: layoutMarginsGuide)
        directionalLayoutMargins = .zero

        container.isLayoutMarginsRelativeArrangement = true
        container.directionalLayoutMargins = .zero
        container.axis = .vertical
        container.alignment = .fill
        container.distribution = .natural
        container.spacing = 0
        container.addArrangedSubview(quotedMessageView)
        container.addArrangedSubview(attachmentsViewContainer)
        container.addArrangedSubview(inputTextContainer)
        quotedMessageView.isHidden = true
        attachmentsViewContainer.isHidden = true
        emojiButton.setImage(appearance.images.emojiIcon, for: .normal)
        inputTextContainer.isLayoutMarginsRelativeArrangement = true
        inputTextContainer.alignment = .center
        inputTextContainer.spacing = 6
        inputTextContainer.directionalLayoutMargins = .init(top: 0, leading: 6, bottom: 0, trailing: 6)
        inputTextContainer.addArrangedSubview(commandLabelView)
        inputTextContainer.addArrangedSubview(textView)
        inputTextContainer.addArrangedSubview(clearButton)
        inputTextContainer.addArrangedSubview(emojiButton)
        inputTextContainer.addArrangedSubview(sendButton)
        inputTextContainer.addArrangedSubview(emptyView)

        commandLabelView.setContentCompressionResistancePriority(.streamRequire, for: .horizontal)
        textView.setContentCompressionResistancePriority(.streamLow, for: .horizontal)
        textView.preservesSuperviewLayoutMargins = false
        textView.tintColor = .white
        textView.textColor = .white
        NSLayoutConstraint.activate([
            clearButton.heightAnchor.pin(equalToConstant: 24),
            clearButton.widthAnchor.pin(equalTo: clearButton.heightAnchor, multiplier: 1),
            emptyView.heightAnchor.pin(equalToConstant: 24),
            emptyView.widthAnchor.pin(equalToConstant: 2),
        ])
        sendButton.pin(anchors: [.width], to: 30)
        sendButton.pin(anchors: [.height], to: 30)
        emojiButton.pin(anchors: [.width], to: 30)
        emojiButton.pin(anchors: [.height], to: 30)
    }

    override open func updateContent() {
        super.updateContent()

        guard let content = self.content else { return }

        if let quotingMessage = content.quotingMessage {
            quotedMessageView.content = .init(
                message: quotingMessage,
                avatarAlignment: .leading
            )
        }

        if let command = content.command {
            commandLabelView.content = command
        }

        Animate {
            self.quotedMessageView.isHidden = content.quotingMessage == nil
            self.commandLabelView.isHidden = content.command == nil
            self.clearButton.isHidden = content.command == nil
        }
    }
}
