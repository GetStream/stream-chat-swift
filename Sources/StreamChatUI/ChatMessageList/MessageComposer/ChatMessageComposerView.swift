//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatMessageComposerView = _ChatMessageComposerView<NoExtraData>

internal class _ChatMessageComposerView<ExtraData: ExtraDataTypes>: _View,
    UIConfigProvider {
    // MARK: - Properties
    
    internal var attachmentsViewHeight: CGFloat = .zero
    internal var stateIconHeight: CGFloat = .zero
    
    // MARK: - Subviews

    internal private(set) lazy var container = ContainerStackView()
        .withoutAutoresizingMaskConstraints
    
    internal private(set) lazy var quotedMessageView = uiConfig
        .messageComposer
        .quotedMessageView.init()
        .withoutAutoresizingMaskConstraints
    
    internal private(set) lazy var imageAttachmentsView = uiConfig
        .messageComposer
        .imageAttachmentsView.init()
        .withoutAutoresizingMaskConstraints
    
    internal private(set) lazy var documentAttachmentsView = uiConfig
        .messageComposer
        .documentAttachmentsView.init()
        .withoutAutoresizingMaskConstraints
    
    internal private(set) lazy var messageInputView = uiConfig
        .messageComposer
        .messageInputView.init()
        .withoutAutoresizingMaskConstraints
    
    internal private(set) lazy var sendButton = uiConfig
        .messageComposer
        .sendButton.init()
        .withoutAutoresizingMaskConstraints
    
    internal private(set) lazy var attachmentButton: UIButton = uiConfig
        .messageComposer
        .composerButton.init()
        .withoutAutoresizingMaskConstraints
    
    internal private(set) lazy var commandsButton: UIButton = uiConfig
        .messageComposer
        .composerButton.init()
        .withoutAutoresizingMaskConstraints
    
    internal private(set) lazy var shrinkInputButton: UIButton = uiConfig
        .messageComposer
        .composerButton.init()
        .withoutAutoresizingMaskConstraints
    
    internal private(set) lazy var stateIcon: UIImageView = {
        let imageView = UIImageView().withoutAutoresizingMaskConstraints
        imageView.contentMode = .center
        imageView.widthAnchor.pin(equalTo: imageView.heightAnchor, multiplier: 1).isActive = true
        return imageView
    }()
    
    internal private(set) lazy var dismissButton: UIButton = uiConfig
        .messageComposer
        .composerButton.init()
        .withoutAutoresizingMaskConstraints
    
    internal private(set) lazy var titleLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
    
    internal private(set) lazy var checkmarkControl: _ChatMessageComposerCheckmarkControl<ExtraData> = uiConfig
        .messageComposer
        .checkmarkControl.init()
        .withoutAutoresizingMaskConstraints
    
    // MARK: - Overrides
    
    override internal func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard superview != nil else { return }
        
        setUp()
        setUpLayout()
        (self as! Self).applyDefaultAppearance()
        setUpAppearance()
        updateContent()
    }
    
    override internal var intrinsicContentSize: CGSize {
        let size = CGSize(
            width: UIView.noIntrinsicMetric,
            height: container.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        )
        return size
    }
    
    // MARK: - internal
    
    override internal func defaultAppearance() {
        super.defaultAppearance()
        stateIconHeight = 40
        
        backgroundColor = uiConfig.colorPalette.popoverBackground
        
        container.centerStackView.clipsToBounds = true
        container.centerStackView.layer.cornerRadius = 25
        container.centerStackView.layer.borderWidth = 1
        container.centerStackView.layer.borderColor = uiConfig.colorPalette.border.cgColor
        
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
        titleLabel.font = uiConfig.fonts.bodyBold
        titleLabel.adjustsFontForContentSizeCategory = true
    }
    
    override internal func setUpLayout() {
        super.setUpLayout()
        embed(container)
                
        container.preservesSuperviewLayoutMargins = true
        container.isLayoutMarginsRelativeArrangement = true
        
        container.spacing = UIStackView.spacingUseSystem
        
        container.topStackView.alignment = .fill
        container.topStackView.addArrangedSubview(stateIcon)
        container.topStackView.addArrangedSubview(titleLabel)
        container.topStackView.addArrangedSubview(dismissButton)
        
        stateIcon.heightAnchor.pin(equalToConstant: stateIconHeight).isActive = true
        
        container.centerStackView.isHidden = false
        container.centerStackView.axis = .vertical
        container.centerStackView.alignment = .fill
        
        quotedMessageView.isHidden = true
        container.centerStackView.addArrangedSubview(quotedMessageView)
        container.centerStackView.addArrangedSubview(imageAttachmentsView)
        container.centerStackView.addArrangedSubview(documentAttachmentsView)
        
        container.centerStackView.addArrangedSubview(messageInputView)
        messageInputView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        container.rightStackView.isHidden = false
        container.rightStackView.alignment = .center
        container.rightStackView.spacing = UIStackView.spacingUseSystem
        container.rightStackView.addArrangedSubview(sendButton)
        
        container.leftStackView.isHidden = false
        container.leftStackView.alignment = .center
        container.leftStackView.addArrangedSubview(shrinkInputButton)
        container.leftStackView.addArrangedSubview(attachmentButton)
        container.leftStackView.addArrangedSubview(commandsButton)
        
        container.bottomStackView.addArrangedSubview(checkmarkControl)
        
        [shrinkInputButton, attachmentButton, commandsButton, sendButton, dismissButton]
            .forEach { button in
                button.pin(anchors: [.width], to: button.intrinsicContentSize.width)
                button.pin(anchors: [.height], to: button.intrinsicContentSize.height)
            }

        imageAttachmentsView.isHidden = true
        documentAttachmentsView.isHidden = true
        shrinkInputButton.isHidden = true
    }
    
    internal func setCheckmarkView(hidden: Bool) {
        if container.bottomStackView.isHidden != hidden {
            container.bottomStackView.isHidden = hidden
        }
    }
}
