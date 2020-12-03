//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

open class ChatChannelMessageInputView<ExtraData: UIExtraDataTypes>: UIView {
    // MARK: - Properties
    
    public let uiConfig: UIConfig<ExtraData>
    
    var numberOfLines: Int {
        guard let font = textView.font else { return 0 }
        let textHeight = textView.contentSize.height - textView.textContainerInset.top - textView.textContainerInset.bottom
        return Int(textHeight / font.lineHeight)
    }
    
    var calculatedHeight: CGFloat {
        textView.contentSize.height // + safeAreaInsets.bottom
    }
    
    // MARK: - Subviews
    
    public private(set) lazy var container = ContainerStackView().withoutAutoresizingMaskConstraints
        
    public private(set) lazy var textView = UITextView().withoutAutoresizingMaskConstraints
    
    public private(set) lazy var slashCommandView: MessageInputSlashCommandView = .init()
    
    public private(set) lazy var rightAccessoryButton: UIButton = {
        let button = UIButton().withoutAutoresizingMaskConstraints
        if #available(iOS 13.0, *) {
            button.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
        }
        button.widthAnchor.constraint(equalTo: button.heightAnchor, multiplier: 1).isActive = true
        return button
    }()
    
    // MARK: - Init
    
    public required init(
        uiConfig: UIConfig<ExtraData> = .default
    ) {
        self.uiConfig = uiConfig
        
        super.init(frame: .zero)
        
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
    
    // MARK: - Overrides
    
    override open var intrinsicContentSize: CGSize {
        CGSize(width: super.intrinsicContentSize.width, height: calculatedHeight)
    }
    
    // MARK: - Public
    
    open func setupAppearance() {
        textView.text = "Hi"
    }
    
    open func setupLayout() {
        container.preservesSuperviewLayoutMargins = true
        container.isLayoutMarginsRelativeArrangement = true
        container.spacing = UIStackView.spacingUseSystem
        
        container.leftStackView.alignment = .center
        container.leftStackView.addArrangedSubview(slashCommandView)
        slashCommandView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        textView.isScrollEnabled = false
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        container.centerStackView.isHidden = false
        container.centerStackView.addArrangedSubview(textView)
        
        container.rightStackView.isHidden = false
        container.rightStackView.alignment = .center
        container.rightStackView.addArrangedSubview(rightAccessoryButton)
        rightAccessoryButton.widthAnchor.constraint(equalToConstant: 20).isActive = true
        
        rightAccessoryButton.isHidden = true
    }
}
