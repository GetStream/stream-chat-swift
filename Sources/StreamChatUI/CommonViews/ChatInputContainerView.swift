//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatInputContainerView = _ChatInputContainerView<NoExtraData>

open class _ChatInputContainerView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    // MARK: - Properties
    
    open var rightAccessoryButtonHeight: CGFloat = 30
    
    // MARK: - Subviews
    
    public private(set) lazy var container = UIStackView().withoutAutoresizingMaskConstraints
        
    public private(set) lazy var textView = uiConfig
        .messageComposer
        .textView.init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var slashCommandView = uiConfig
        .messageComposer
        .slashCommandView.init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var rightAccessoryButton: UIButton = {
        let button = UIButton().withoutAutoresizingMaskConstraints
        button.widthAnchor.pin(equalTo: button.heightAnchor, multiplier: 1).isActive = true
        return button
    }()
        
    // MARK: - Public
    
    override public func defaultAppearance() {
        let rightAccessoryImage = uiConfig.images.close1.tinted(with: uiConfig.colorPalette.inactiveTint)
        rightAccessoryButton.setImage(rightAccessoryImage, for: .normal)
    }
    
    override open func setUpLayout() {
        embed(container)

        container.preservesSuperviewLayoutMargins = true
        container.isLayoutMarginsRelativeArrangement = true
        container.alignment = .center

        container.addArrangedSubview(slashCommandView)
        slashCommandView.setContentHuggingPriority(.required, for: .horizontal)

        container.addArrangedSubview(textView)
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)

        container.addArrangedSubview(rightAccessoryButton)

        rightAccessoryButton.heightAnchor.pin(equalToConstant: rightAccessoryButtonHeight).isActive = true
    }

    public func setSlashCommandViews(hidden: Bool) {
        slashCommandView.setAnimatedly(hidden: hidden)
        rightAccessoryButton.setAnimatedly(hidden: hidden)
        slashCommandView.invalidateIntrinsicContentSize()
    }
}
