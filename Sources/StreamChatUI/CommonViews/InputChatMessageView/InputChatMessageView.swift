//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view to input content of a message.
public typealias InputChatMessageView = _InputChatMessageView<NoExtraData>

/// A view to input content of a message.
open class _InputChatMessageView<ExtraData: ExtraDataTypes>: _View, ComponentsProvider, AppearanceProvider {
    /// The content of the view
    public struct Content {
        /// The message that is being quoted.
        var quotingMessage: _ChatMessage<ExtraData>?
        /// The command that the message produces.
        var command: Command?
        /// The document attachments that are part of the message.
        var documentAttachments: [AttachmentPreview]
        /// The image attachments that are part of the message.
        var imageAttachments: [AttachmentPreview]
    }

    /// The content of the view
    public var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The main container stack view that layouts all the message input content views.
    public private(set) lazy var container = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    /// A view that displays the quoted message that the new message is replying.
    public private(set) lazy var quotedMessageView = components
        .quotedMessageView.init()
        .withoutAutoresizingMaskConstraints

    /// A view that displays the image attachments of the new message.
    public private(set) lazy var imageAttachmentsCollectionView: _ChatImageAttachmentsCollectionView<ExtraData> = components
        .messageComposer
        .imageAttachmentsCollectionView.init()
        .withoutAutoresizingMaskConstraints

    /// A view that displays the document attachments of the new message.
    public private(set) lazy var documentAttachmentsCollectionView: _ChatDocumentAttachmentsCollectionView<ExtraData> = components
        .messageComposer
        .documentAttachmentsCollectionView.init()
        .withoutAutoresizingMaskConstraints

    /// The container stack view that layouts the command label, text view and the clean button.
    public private(set) lazy var inputTextContainer = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    /// The input text view to type a new message or command.
    public private(set) lazy var textView: InputTextView = components
        .inputTextView.init()
        .withoutAutoresizingMaskConstraints

    /// The command label that display the command info if a new command is being typed.
    public private(set) lazy var commandLabelView: _CommandLabelView<ExtraData> = components
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
        container.layer.cornerRadius = 18
        container.layer.borderWidth = 1
        container.layer.borderColor = appearance.colorPalette.border.cgColor
    }
    
    override open func setUpLayout() {
        addSubview(container)
        container.pin(to: layoutMarginsGuide)
        directionalLayoutMargins = .zero

        container.isLayoutMarginsRelativeArrangement = true
        container.directionalLayoutMargins = .init(top: 0, leading: 4, bottom: 0, trailing: 4)
        container.axis = .vertical
        container.alignment = .fill
        container.distribution = .natural
        container.spacing = 0
        container.addArrangedSubview(quotedMessageView)
        container.addArrangedSubview(imageAttachmentsCollectionView)
        container.addArrangedSubview(documentAttachmentsCollectionView)
        container.addArrangedSubview(inputTextContainer)
        quotedMessageView.isHidden = true
        imageAttachmentsCollectionView.isHidden = true
        documentAttachmentsCollectionView.isHidden = true

        inputTextContainer.preservesSuperviewLayoutMargins = true
        inputTextContainer.alignment = .center
        inputTextContainer.spacing = 4
        inputTextContainer.addArrangedSubview(commandLabelView)
        inputTextContainer.addArrangedSubview(textView)
        inputTextContainer.addArrangedSubview(clearButton)

        commandLabelView.setContentCompressionResistancePriority(.streamRequire, for: .horizontal)
        textView.setContentCompressionResistancePriority(.streamLow, for: .horizontal)
        textView.preservesSuperviewLayoutMargins = false

        NSLayoutConstraint.activate([
            clearButton.heightAnchor.pin(equalToConstant: 24),
            clearButton.widthAnchor.pin(equalTo: clearButton.heightAnchor, multiplier: 1),
            imageAttachmentsCollectionView.heightAnchor.pin(equalToConstant: 120)
        ])
    }

    override open func updateContent() {
        super.updateContent()

        guard let content = self.content else { return }

        if let quotingMessage = content.quotingMessage {
            quotedMessageView.content = .init(
                message: quotingMessage,
                avatarAlignment: .left
            )
        }

        if let command = content.command {
            commandLabelView.content = command
        }

        documentAttachmentsCollectionView.content = content.documentAttachments
        imageAttachmentsCollectionView.content = content.imageAttachments
        documentAttachmentsCollectionView.isHidden = content.documentAttachments.isEmpty
        imageAttachmentsCollectionView.isHidden = content.imageAttachments.isEmpty

        Animate {
            self.quotedMessageView.isHidden = content.quotingMessage == nil
            self.commandLabelView.isHidden = content.command == nil
            self.clearButton.isHidden = content.command == nil
        }
    }
}
