//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageComposerView = _ChatMessageComposerView<NoExtraData>

open class _ChatMessageComposerView<ExtraData: ExtraDataTypes>: _View,
    UIConfigProvider {
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
    
    public private(set) lazy var messageQuoteView = uiConfig
        .messageQuoteView.init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var imageAttachmentsView = uiConfig
        .messageComposer
        .imageAttachmentsView.init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var documentAttachmentsView = uiConfig
        .messageComposer
        .documentAttachmentsView.init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var messageInputView = uiConfig
        .messageComposer
        .messageInputView.init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var sendButton = uiConfig
        .messageComposer
        .sendButton.init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var editButton = uiConfig
        .messageComposer
        .editButton.init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var attachmentButton: UIButton = uiConfig
        .messageComposer
        .composerButton.init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var commandsButton: UIButton = uiConfig
        .messageComposer
        .composerButton.init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var shrinkInputButton: UIButton = uiConfig
        .messageComposer
        .composerButton.init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var stateIcon: UIImageView = {
        let imageView = UIImageView().withoutAutoresizingMaskConstraints
        imageView.contentMode = .center
        imageView.widthAnchor.pin(equalTo: imageView.heightAnchor, multiplier: 1).isActive = true
        return imageView
    }()
    
    public private(set) lazy var dismissButton: UIButton = uiConfig
        .messageComposer
        .composerButton.init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var titleLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
    
    public private(set) lazy var checkmarkControl: _ChatMessageComposerCheckmarkControl<ExtraData> = uiConfig
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
        
        backgroundColor = uiConfig.colorPalette.popoverBackground
        
        centerContentContainer.clipsToBounds = true
        centerContentContainer.layer.cornerRadius = 25
        centerContentContainer.layer.borderWidth = 1
        centerContentContainer.layer.borderColor = uiConfig.colorPalette.border.cgColor
        
        layer.shadowColor = UIColor.systemGray.cgColor
        layer.shadowOpacity = 1
        layer.shadowOffset = .zero
        layer.shadowRadius = 0.5
        
        let clipIcon = uiConfig.images.messageComposerFileAttachment.tinted(with: uiConfig.colorPalette.inactiveTint)
        attachmentButton.setImage(clipIcon, for: .normal)
        
        let boltIcon = uiConfig.images.messageComposerCommand.tinted(with: uiConfig.colorPalette.inactiveTint)
        commandsButton.setImage(boltIcon, for: .normal)
        
        let shrinkArrowIcon = uiConfig.images.messageComposerShrinkInput
        shrinkInputButton.setImage(shrinkArrowIcon, for: .normal)
        
        let dismissIcon = uiConfig.images.close1.tinted(with: uiConfig.colorPalette.inactiveTint)
        dismissButton.setImage(dismissIcon, for: .normal)
        
        titleLabel.textAlignment = .center
        titleLabel.textColor = uiConfig.colorPalette.text
        titleLabel.font = uiConfig.font.bodyBold
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
        container.hideSubview(bottomContainer)
        container.hideSubview(topContainer)

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
        centerContentContainer.hideSubview(messageQuoteView, animated: false)
        centerContentContainer.hideSubview(imageAttachmentsView, animated: false)
        centerContentContainer.hideSubview(documentAttachmentsView, animated: false)
        imageAttachmentsView.heightAnchor.pin(equalToConstant: 120).isActive = true

        centerRightContainer.alignment = .center
        centerRightContainer.spacing = .auto
        centerRightContainer.addArrangedSubview(sendButton)
        centerRightContainer.addArrangedSubview(editButton)
        centerRightContainer.hideSubview(editButton)

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
    
    open func setCheckmarkView(hidden: Bool) {
        if hidden {
            container.hideSubview(bottomContainer)
        } else {
            container.showSubview(bottomContainer)
        }
    }
}
