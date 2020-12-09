//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelMessageInputView<ExtraData: ExtraDataTypes>: UIView {
    // MARK: - Properties
    
    public let uiConfig: UIConfig<ExtraData>
    
    public var textViewHeight: CGFloat {
        guard let font = textView.font, let text = textView.text else { return 0 }

        let width = textView.frame.width - textView.textContainerInset.right - textView.textContainerInset.left
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(
            with: constraintRect,
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil
        )
        return boundingBox.height
    }
    
    // MARK: - Subviews
    
    public private(set) lazy var container = ContainerStackView().withoutAutoresizingMaskConstraints
        
    public private(set) lazy var textView: ChatChannelMessageInputTextView<ExtraData> = {
        uiConfig.messageComposer.textView.init().withoutAutoresizingMaskConstraints
    }()
    
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

        setupLayout()
    }
    
    // MARK: - Overrides
    
    override open var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: textViewHeight)
    }
    
    // MARK: - Public
    
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
        
        container.rightStackView.alignment = .center
        container.rightStackView.addArrangedSubview(rightAccessoryButton)
        rightAccessoryButton.widthAnchor.constraint(equalToConstant: 20).isActive = true
    }

    public func setSlashCommandViews(hidden: Bool) {
        container.rightStackView.isHidden = hidden
        container.leftStackView.isHidden = hidden
    }
}
