//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelMessageComposerView<ExtraData: ExtraDataTypes>: UIInputView,
    UIConfigProvider,
    Customizable,
    AppearanceSetting {
    // MARK: - Properties
    
    public var attachmentsViewHeight: CGFloat = .zero
    public var stateIconHeight: CGFloat = .zero
    
    // MARK: - Subviews

    public private(set) lazy var container = ContainerStackView()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var replyView = uiConfig
        .messageComposer
        .replyBubbleView.init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var attachmentsView: MessageComposerAttachmentsView<ExtraData> = uiConfig
        .messageComposer
        .attachmentsView.init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var messageInputView: ChatChannelMessageInputView<ExtraData> = uiConfig
        .messageComposer
        .messageInputView.init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var sendButton: MessageComposerSendButton<ExtraData> = uiConfig
        .messageComposer
        .sendButton.init()
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
        imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: 1).isActive = true
        return imageView
    }()
    
    public private(set) lazy var dismissButton: UIButton = uiConfig
        .messageComposer
        .composerButton.init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var titleLabel: UILabel = UILabel().withoutAutoresizingMaskConstraints
    
    // MARK: - Init
    
    public required init() {
        super.init(frame: .zero, inputViewStyle: .default)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Overrides
    
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard superview != nil else { return }
        
        setUp()
        (self as! Self).applyDefaultAppearance()
        setUpAppearance()
        setUpLayout()
        updateContent()
    }
    
    override open var intrinsicContentSize: CGSize {
        let size = CGSize(
            width: UIView.noIntrinsicMetric,
            height: container.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        )
        return size
    }
    
    // MARK: - Public

    open func setUp() {}
    
    open func defaultAppearance() {
        attachmentsViewHeight = 80
        stateIconHeight = 40
        
        backgroundColor = uiConfig.colorPalette.messageComposerBackground
        
        container.centerStackView.clipsToBounds = true
        container.centerStackView.layer.cornerRadius = 25
        container.centerStackView.layer.borderWidth = 1
        container.centerStackView.layer.borderColor = uiConfig.colorPalette.messageComposerBorder.cgColor
        
        layer.shadowColor = UIColor.systemGray.cgColor
        layer.shadowOpacity = 1
        layer.shadowOffset = .zero
        layer.shadowRadius = 0.5
        
        let clipIcon = UIImage(named: "clip", in: .streamChatUI)?.tinted(with: uiConfig.colorPalette.messageComposerButton)
        attachmentButton.setImage(clipIcon, for: .normal)
        
        let boltIcon = UIImage(named: "bolt", in: .streamChatUI)?.tinted(with: uiConfig.colorPalette.messageComposerButton)
        commandsButton.setImage(boltIcon, for: .normal)
        
        let shrinkArrowIcon = UIImage(named: "shrinkInputArrow", in: .streamChatUI)
        shrinkInputButton.setImage(shrinkArrowIcon, for: .normal)
        
        let dismissIcon =
            UIImage(named: "dismissInCircle", in: .streamChatUI)?.tinted(with: uiConfig.colorPalette.messageComposerButton)
        dismissButton.setImage(dismissIcon, for: .normal)
        
        titleLabel.textAlignment = .center
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
    }
    
    open func setUpAppearance() {}
    
    open func setUpLayout() {
        embed(container)
        
        preservesSuperviewLayoutMargins = true
        
        container.preservesSuperviewLayoutMargins = true
        container.isLayoutMarginsRelativeArrangement = true
        
        container.spacing = UIStackView.spacingUseSystem
        
        container.topStackView.alignment = .center
        container.topStackView.addArrangedSubview(stateIcon)
        container.topStackView.addArrangedSubview(titleLabel)
        container.topStackView.addArrangedSubview(dismissButton)
        
        stateIcon.heightAnchor.constraint(equalToConstant: stateIconHeight).isActive = true
        
        container.centerStackView.isHidden = false
        container.centerStackView.axis = .vertical
        container.centerStackView.alignment = .fill
        
        replyView.isHidden = true
        container.centerStackView.addArrangedSubview(replyView)
        container.centerStackView.addArrangedSubview(attachmentsView)
        attachmentsView.heightAnchor.constraint(equalToConstant: attachmentsViewHeight).isActive = true
        
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
        
        [shrinkInputButton, attachmentButton, commandsButton, sendButton, dismissButton]
            .forEach { button in
                button.pin(anchors: [.width], to: button.intrinsicContentSize.width)
                button.pin(anchors: [.height], to: button.intrinsicContentSize.height)
            }

        attachmentsView.isHidden = true
        shrinkInputButton.isHidden = true
    }
    
    open func updateContent() {}
}
