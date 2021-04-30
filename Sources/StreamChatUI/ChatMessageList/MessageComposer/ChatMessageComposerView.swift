//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageComposerView = _ChatMessageComposerView<NoExtraData>

open class _ChatMessageComposerView<ExtraData: ExtraDataTypes>: _View, ThemeProvider {
    public private(set) lazy var container = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var headerView = UIView()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var bottomContainer = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var centerContainer = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var centerContentContainer = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var centerLeftContainer = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var centerRightContainer = ContainerStackView()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var messageQuoteView = components
        .messageQuoteView.init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var imageAttachmentsView = components
        .messageComposer
        .imageAttachmentsCollectionView.init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var documentAttachmentsView = components
        .messageComposer
        .documentAttachmentsCollectionView.init()
        .withoutAutoresizingMaskConstraints

    /// A view to input content of a message.
    public private(set) lazy var messageInputView = components
        .messageInputView.init()
        .withoutAutoresizingMaskConstraints

    /// A button to send a message.
    public private(set) lazy var sendButton: UIButton = components
        .sendButton.init()
        .withoutAutoresizingMaskConstraints

    /// A button to confirm when editing a message.
    public private(set) lazy var confirmButton: UIButton = components
        .confirmButton.init()
        .withoutAutoresizingMaskConstraints

    /// A button to open the user attachments.
    public private(set) lazy var attachmentButton: UIButton = components
        .attachmentButton.init()
        .withoutAutoresizingMaskConstraints

    /// A button to open the available commands.
    public private(set) lazy var commandsButton: UIButton = components
        .commandsButton.init()
        .withoutAutoresizingMaskConstraints

    /// A button to show or hide the left action buttons.
    public private(set) lazy var shrinkInputButton: UIButton = components
        .shrinkInputButton.init()
        .withoutAutoresizingMaskConstraints

    /// A button to dismiss the current state (quoting, editing, etc..).
    public private(set) lazy var dismissButton: UIButton = components
        .closeButton.init()
        .withoutAutoresizingMaskConstraints

    /// A label part of the header view to display the current state (quoting, editing, etc..).
    public private(set) lazy var titleLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport

    /// A checkbox to check/uncheck if the message should also
    /// be sent to the channel while replying in a thread.
    public private(set) lazy var checkboxControl: ChatCheckboxControl = components
        .checkmarkControl.init()
        .withoutAutoresizingMaskConstraints

    override open func setUpAppearance() {
        super.setUpAppearance()
        
        backgroundColor = appearance.colorPalette.popoverBackground
        layer.shadowColor = UIColor.systemGray.cgColor
        layer.shadowOpacity = 1
        layer.shadowOffset = .zero
        layer.shadowRadius = 0.5
        
        centerContentContainer.clipsToBounds = true
        centerContentContainer.layer.cornerRadius = 20
        centerContentContainer.layer.borderWidth = 1
        centerContentContainer.layer.borderColor = appearance.colorPalette.border.cgColor

        titleLabel.textAlignment = .center
        titleLabel.textColor = appearance.colorPalette.text
        titleLabel.font = appearance.fonts.bodyBold
        titleLabel.adjustsFontForContentSizeCategory = true
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        embed(container)

        container.isLayoutMarginsRelativeArrangement = true
        container.axis = .vertical
        container.alignment = .fill
        container.addArrangedSubview(headerView)
        container.addArrangedSubview(centerContainer)
        container.addArrangedSubview(bottomContainer)
        bottomContainer.isHidden = true
        headerView.isHidden = true

        bottomContainer.addArrangedSubview(checkboxControl)

        headerView.addSubview(titleLabel)
        headerView.addSubview(dismissButton)

        centerContainer.axis = .horizontal
        centerContainer.alignment = .fill
        centerContainer.spacing = .auto
        centerContainer.addArrangedSubview(centerLeftContainer)
        centerContainer.addArrangedSubview(centerContentContainer)
        centerContainer.addArrangedSubview(centerRightContainer)

        centerContentContainer.axis = .vertical
        centerContentContainer.alignment = .fill
        centerContentContainer.distribution = .natural
        centerContentContainer.spacing = 0
        centerContentContainer.addArrangedSubview(messageQuoteView)
        centerContentContainer.addArrangedSubview(imageAttachmentsView)
        centerContentContainer.addArrangedSubview(documentAttachmentsView)
        centerContentContainer.addArrangedSubview(messageInputView)
        messageQuoteView.isHidden = true
        imageAttachmentsView.isHidden = true
        documentAttachmentsView.isHidden = true

        centerRightContainer.alignment = .center
        centerRightContainer.spacing = .auto
        centerRightContainer.addArrangedSubview(sendButton)
        centerRightContainer.addArrangedSubview(confirmButton)
        confirmButton.isHidden = true

        leadingContainer.axis = .horizontal
        leadingContainer.alignment = .center
        leadingContainer.spacing = .auto
        leadingContainer.addArrangedSubview(attachmentButton)
        leadingContainer.addArrangedSubview(commandsButton)
        leadingContainer.addArrangedSubview(shrinkInputButton)

        dismissButton.widthAnchor.pin(equalToConstant: 24).isActive = true
        dismissButton.heightAnchor.pin(equalToConstant: 24).isActive = true
        dismissButton.trailingAnchor.pin(equalTo: centerRightContainer.trailingAnchor).isActive = true
        titleLabel.centerXAnchor.pin(equalTo: centerXAnchor).isActive = true
        titleLabel.pin(anchors: [.top, .bottom], to: headerView)
        imageAttachmentsView.heightAnchor.pin(equalToConstant: 120).isActive = true
        messageInputView.inputTextView.preservesSuperviewLayoutMargins = false
        
        [shrinkInputButton, attachmentButton, commandsButton, sendButton, confirmButton]
            .forEach { button in
                button.pin(anchors: [.width], to: 20)
                button.pin(anchors: [.height], to: 20)
            }
    }
}
