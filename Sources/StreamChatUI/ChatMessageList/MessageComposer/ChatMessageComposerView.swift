//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageComposerView = _ChatMessageComposerView<NoExtraData>

open class _ChatMessageComposerView<ExtraData: ExtraDataTypes>: _View, ThemeProvider {
    public private(set) lazy var container = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var topContainer = ContainerStackView()
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
        .imageAttachmentsView.init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var documentAttachmentsView = components
        .messageComposer
        .documentAttachmentsView.init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var messageInputView = components
        .messageInputView.init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var sendButton = components
        .messageComposer
        .sendButton.init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var editButton = components
        .messageComposer
        .editButton.init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var attachmentButton: UIButton = components
        .messageComposer
        .composerButton.init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var commandsButton: UIButton = components
        .messageComposer
        .composerButton.init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var shrinkInputButton: UIButton = components
        .messageComposer
        .composerButton.init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var stateIcon: UIImageView = {
        let imageView = UIImageView().withoutAutoresizingMaskConstraints
        imageView.contentMode = .center
        imageView.widthAnchor.pin(equalTo: imageView.heightAnchor, multiplier: 1).isActive = true
        return imageView
    }()
    
    public private(set) lazy var dismissButton: UIButton = components
        .messageComposer
        .composerButton.init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var titleLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
    
    public private(set) lazy var checkmarkControl: ChatMessageComposerCheckmarkControl = components
        .messageComposer
        .checkmarkControl.init()
        .withoutAutoresizingMaskConstraints
    
    // MARK: - Overrides
    
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard superview != nil else { return }
        
        setUp()
        setUpLayout()
        
        setUpAppearance()
        updateContent()
    }
    
    // MARK: - Public
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        
        backgroundColor = appearance.colorPalette.popoverBackground
        
        centerContentContainer.clipsToBounds = true
        centerContentContainer.layer.cornerRadius = 25
        centerContentContainer.layer.borderWidth = 1
        centerContentContainer.layer.borderColor = appearance.colorPalette.border.cgColor
        
        layer.shadowColor = UIColor.systemGray.cgColor
        layer.shadowOpacity = 1
        layer.shadowOffset = .zero
        layer.shadowRadius = 0.5
        
        let clipIcon = appearance.images.messageComposerFileAttachment
            .tinted(with: appearance.colorPalette.inactiveTint)
        attachmentButton.setImage(clipIcon, for: .normal)
        
        let boltIcon = appearance.images.messageComposerCommand.tinted(with: appearance.colorPalette.inactiveTint)
        commandsButton.setImage(boltIcon, for: .normal)
        
        let shrinkArrowIcon = appearance.images.messageComposerShrinkInput
        shrinkInputButton.setImage(shrinkArrowIcon, for: .normal)
        
        let dismissIcon = appearance.images.close1.tinted(with: appearance.colorPalette.inactiveTint)
        dismissButton.setImage(dismissIcon, for: .normal)
        
        titleLabel.textAlignment = .center
        titleLabel.textColor = appearance.colorPalette.text
        titleLabel.font = appearance.fonts.bodyBold
        titleLabel.adjustsFontForContentSizeCategory = true
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        embed(container)

        container.isLayoutMarginsRelativeArrangement = true
        container.spacing = 0
        container.axis = .vertical
        container.alignment = .fill
        container.addArrangedSubview(topContainer)
        container.addArrangedSubview(centerContainer)
        container.addArrangedSubview(bottomContainer)
        bottomContainer.isHidden = true
        topContainer.isHidden = true

        bottomContainer.addArrangedSubview(checkmarkControl)

        topContainer.alignment = .fill
        topContainer.addArrangedSubview(stateIcon)
        topContainer.addArrangedSubview(titleLabel)
        topContainer.addArrangedSubview(dismissButton)
        stateIcon.heightAnchor.pin(equalToConstant: 40).isActive = true

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
        imageAttachmentsView.heightAnchor.pin(equalToConstant: 120).isActive = true

        centerRightContainer.alignment = .center
        centerRightContainer.spacing = .auto
        centerRightContainer.addArrangedSubview(sendButton)
        centerRightContainer.addArrangedSubview(editButton)
        editButton.isHidden = true

        centerLeftContainer.axis = .horizontal
        centerLeftContainer.alignment = .center
        centerLeftContainer.spacing = .auto
        centerLeftContainer.addArrangedSubview(attachmentButton)
        centerLeftContainer.addArrangedSubview(commandsButton)
        centerLeftContainer.addArrangedSubview(shrinkInputButton)
        
        [shrinkInputButton, attachmentButton, commandsButton, sendButton, editButton, dismissButton]
            .forEach { button in
                button.pin(anchors: [.width], to: 20)
                button.pin(anchors: [.height], to: 20)
            }
    }
}
