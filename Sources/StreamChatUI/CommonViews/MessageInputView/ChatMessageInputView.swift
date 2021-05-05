//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view to input content of a message.
public typealias ChatMessageInputView = _ChatMessageInputView<NoExtraData>

/// A view to input content of a message.
open class _ChatMessageInputView<ExtraData: ExtraDataTypes>: _View, ComponentsProvider, AppearanceProvider {
    /// The main container stack view that layouts all the message input content views.
    public private(set) lazy var container = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    /// A view that displays the quoted message that the new message is replying.
    public private(set) lazy var quotedMessageView = components
        .quotedMessageView.init()
        .withoutAutoresizingMaskConstraints

    /// A view that displays the image attachments of the new message.
    public private(set) lazy var imageAttachmentsView = components
        .messageComposer
        .imageAttachmentsCollectionView.init()
        .withoutAutoresizingMaskConstraints

    /// A view that displays the document attachments of the new message.
    public private(set) lazy var documentAttachmentsView = components
        .messageComposer
        .documentAttachmentsCollectionView.init()
        .withoutAutoresizingMaskConstraints

    /// The container stack view that layouts the command label, text view and the clean button.
    public private(set) lazy var inputTextContainer = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    /// The input text view to type a new message or command.
    public private(set) lazy var inputTextView: ChatInputTextView = components
        .inputTextView.init()
        .withoutAutoresizingMaskConstraints

    /// The command label that display the command info if a new command is being typed.
    public private(set) lazy var commandLabel: _ChatCommandLabel<ExtraData> = components
        .commandLabel.init()
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
        container.addArrangedSubview(imageAttachmentsView)
        container.addArrangedSubview(documentAttachmentsView)
        container.addArrangedSubview(inputTextContainer)
        quotedMessageView.isHidden = true
        imageAttachmentsView.isHidden = true
        documentAttachmentsView.isHidden = true

        inputTextContainer.preservesSuperviewLayoutMargins = true
        inputTextContainer.alignment = .center
        inputTextContainer.spacing = 4
        inputTextContainer.addArrangedSubview(commandLabel)
        inputTextContainer.addArrangedSubview(inputTextView)
        inputTextContainer.addArrangedSubview(clearButton)

        commandLabel.setContentCompressionResistancePriority(.streamRequire, for: .horizontal)
        inputTextView.setContentCompressionResistancePriority(.streamLow, for: .horizontal)
        inputTextView.preservesSuperviewLayoutMargins = false

        NSLayoutConstraint.activate([
            clearButton.heightAnchor.pin(equalToConstant: 24),
            clearButton.widthAnchor.pin(equalTo: clearButton.heightAnchor, multiplier: 1),
            imageAttachmentsView.heightAnchor.pin(equalToConstant: 120)
        ])
    }

    public func setSlashCommandViews(hidden: Bool) {
        commandLabel.isHidden = hidden
        clearButton.isHidden = hidden
    }
}
