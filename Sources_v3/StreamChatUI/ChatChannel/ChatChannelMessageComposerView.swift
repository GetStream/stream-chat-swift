//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

open class ChatChannelMessageComposerView<ExtraData: UIExtraDataTypes>: UIInputView {
    // MARK: - Properties
    
    public var buttonHeight: CGFloat = 20
    
    public let uiConfig: UIConfig<ExtraData>
        
    // MARK: - Subviews

    public private(set) lazy var container = ContainerStackView().withoutAutoresizingMaskConstraints
    
    public private(set) lazy var replyView: UIView = .init()
    
    public private(set) lazy var attachmentsView: MessageComposerAttachmentsView<ExtraData> = .init(uiConfig: uiConfig)
    
    public private(set) lazy var messageInputView: ChatChannelMessageInputView<ExtraData> = .init(uiConfig: uiConfig)
    
    public private(set) lazy var sendButton: UIButton = {
        let button = UIButton().withoutAutoresizingMaskConstraints
        if #available(iOS 13.0, *) {
            button.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        }
        button.widthAnchor.constraint(equalTo: button.heightAnchor, multiplier: 1).isActive = true
        return button
    }()
        
    public private(set) lazy var searchButton: UIButton = {
        let button = UIButton().withoutAutoresizingMaskConstraints
        if #available(iOS 13.0, *) {
            button.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        }
        button.widthAnchor.constraint(equalTo: button.heightAnchor, multiplier: 1).isActive = true
        return button
    }()
    
    public private(set) lazy var attachmentButton: UIButton = {
        let button = UIButton().withoutAutoresizingMaskConstraints
        if #available(iOS 13.0, *) {
            button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        }
        button.widthAnchor.constraint(equalTo: button.heightAnchor, multiplier: 1).isActive = true
        return button
    }()

    public private(set) lazy var boltButton: UIButton = {
        let button = UIButton().withoutAutoresizingMaskConstraints
        if #available(iOS 13.0, *) {
            button.setImage(UIImage(systemName: "bolt.fill"), for: .normal)
        }
        button.widthAnchor.constraint(equalTo: button.heightAnchor, multiplier: 1).isActive = true
        return button
    }()
    
    // MARK: - Init
    
    public required init(
        uiConfig: UIConfig<ExtraData> = .default
    ) {
        self.uiConfig = uiConfig
        
        super.init(frame: .zero, inputViewStyle: .default)
        
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        uiConfig = .default
        
        super.init(coder: coder)
        
        commonInit()
    }
    
    public func commonInit() {
        embed(container)

        setupAppearance()
        setupLayout()
    }
    
    // MARK: - Public
    
    open func setupAppearance() {
        backgroundColor = uiConfig.colorPalette.messageComposerBackground
    }
    
    open func setupLayout() {
        container.preservesSuperviewLayoutMargins = true
        container.isLayoutMarginsRelativeArrangement = true
        
        container.centerContainerStackView.spacing = UIStackView.spacingUseSystem
        
        container.centerStackView.isHidden = false
        container.centerStackView.axis = .vertical
        container.centerStackView.alignment = .fill
        container.centerStackView.addArrangedSubview(replyView)
        
        container.centerStackView.addArrangedSubview(attachmentsView)
        attachmentsView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        container.centerStackView.addArrangedSubview(messageInputView)
        messageInputView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        container.rightStackView.isHidden = false
        container.rightStackView.alignment = .center
        container.rightStackView.spacing = UIStackView.spacingUseSystem
        searchButton.isHidden = true
        container.rightStackView.addArrangedSubview(searchButton)
        container.rightStackView.addArrangedSubview(sendButton)
        
        container.leftStackView.isHidden = false
        container.leftStackView.alignment = .center
        container.leftStackView.spacing = UIStackView.spacingUseSystem
        container.leftStackView.addArrangedSubview(attachmentButton)
        boltButton.isHidden = true
        container.leftStackView.addArrangedSubview(boltButton)
        
        searchButton.widthAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        attachmentButton.widthAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        boltButton.widthAnchor.constraint(equalToConstant: buttonHeight).isActive = true

        attachmentsView.isHidden = true

        addObserver(self, forKeyPath: "safeAreaInsets", options: .new, context: nil)
        messageInputView.textView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }
    
    // MARK: - Overrides
    
    override open var intrinsicContentSize: CGSize {
        let size = CGSize(
            width: .zero,
            height: container.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        )
        return size
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
                
        container.centerStackView.clipsToBounds = true
        container.centerStackView.layer.cornerRadius = 20
        container.centerStackView.layer.borderWidth = 2
        container.centerStackView.layer.borderColor = uiConfig.colorPalette.messageComposerBorder.cgColor
    }
    
    // There are some issues with new-style KVO so that is something that will need attention later.
    // swiftlint:disable block_based_kvo
    override open func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if object as AnyObject? === messageInputView.textView, keyPath == "contentSize" {
            invalidateIntrinsicContentSize()
        } else if object as AnyObject? === self, keyPath == "safeAreaInsets" {
            invalidateIntrinsicContentSize()
        }
    }
}
