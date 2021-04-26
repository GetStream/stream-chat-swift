//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageComposerInputContainerView = _ChatMessageComposerInputContainerView<NoExtraData>

open class _ChatMessageComposerInputContainerView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    // MARK: - Properties
    
    open var rightAccessoryButtonHeight: CGFloat = 30

    // MARK: - Subviews

    public private(set) lazy var container = ContainerStackView()
        .withoutAutoresizingMaskConstraints

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
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        let rightAccessoryImage = uiConfig.images.close1.tinted(with: uiConfig.colorPalette.inactiveTint)
        rightAccessoryButton.setImage(rightAccessoryImage, for: .normal)
    }
    
    override open func setUpLayout() {
        embed(container)

        container.preservesSuperviewLayoutMargins = true
        container.isLayoutMarginsRelativeArrangement = true
        container.alignment = .center
        container.spacing = 4

        container.addArrangedSubview(slashCommandView)
        container.addArrangedSubview(textView)
        container.addArrangedSubview(rightAccessoryButton)

        slashCommandView.setContentCompressionResistancePriority(.streamRequire, for: .horizontal)
        textView.setContentCompressionResistancePriority(.streamLow, for: .horizontal)

        rightAccessoryButton.heightAnchor.pin(equalToConstant: rightAccessoryButtonHeight).isActive = true
    }

    public func setSlashCommandViews(hidden: Bool) {
        slashCommandView.isHidden = hidden
        rightAccessoryButton.isHidden = hidden
    }
}
