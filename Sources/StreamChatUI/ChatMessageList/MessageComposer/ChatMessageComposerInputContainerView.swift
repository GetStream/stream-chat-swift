//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatMessageComposerInputContainerView = _ChatMessageComposerInputContainerView<NoExtraData>

internal class _ChatMessageComposerInputContainerView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    // MARK: - Properties
    
    internal var rightAccessoryButtonHeight: CGFloat = 30
    
    // MARK: - Subviews
    
    internal private(set) lazy var container = UIStackView().withoutAutoresizingMaskConstraints
        
    internal private(set) lazy var textView = uiConfig
        .messageComposer
        .textView.init()
        .withoutAutoresizingMaskConstraints
    
    internal private(set) lazy var slashCommandView = uiConfig
        .messageComposer
        .slashCommandView.init()
        .withoutAutoresizingMaskConstraints
    
    internal private(set) lazy var rightAccessoryButton: UIButton = {
        let button = UIButton().withoutAutoresizingMaskConstraints
        button.widthAnchor.pin(equalTo: button.heightAnchor, multiplier: 1).isActive = true
        return button
    }()
        
    // MARK: - internal
    
    override internal func defaultAppearance() {
        let rightAccessoryImage = uiConfig.images.close1.tinted(with: uiConfig.colorPalette.inactiveTint)
        rightAccessoryButton.setImage(rightAccessoryImage, for: .normal)
    }
    
    override internal func setUpLayout() {
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

    internal func setSlashCommandViews(hidden: Bool) {
        slashCommandView.setAnimatedly(hidden: hidden)
        rightAccessoryButton.setAnimatedly(hidden: hidden)
        slashCommandView.invalidateIntrinsicContentSize()
    }
}
