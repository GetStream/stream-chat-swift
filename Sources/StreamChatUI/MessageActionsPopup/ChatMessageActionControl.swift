//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Button for action displayed in `_ChatMessageActionsView`.
public typealias ChatMessageActionControl = _ChatMessageActionControl<NoExtraData>

/// Button for action displayed in `_ChatMessageActionsView`.
open class _ChatMessageActionControl<ExtraData: ExtraDataTypes>: _Control, UIConfigProvider {
    /// The data this view component shows.
    public var content: ChatMessageActionItem? {
        didSet { updateContentIfNeeded() }
    }

    override open var isHighlighted: Bool {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// `ContainerStackView` that encapsulates `titleLabel` and `imageView`.
    public lazy var containerStackView: ContainerStackView = ContainerStackView(alignment: .center)
        .withoutAutoresizingMaskConstraints

    /// `UILabel` to show `title`.
    public lazy var titleLabel: UILabel = UILabel()

    /// `UIImageView` to show `image`.
    public lazy var imageView: UIImageView = UIImageView()

    override open func setUpAppearance() {
        super.setUpAppearance()
        titleLabel.font = uiConfig.font.body
        titleLabel.adjustsFontForContentSizeCategory = true
    }

    override open func setUp() {
        super.setUp()
        containerStackView.isUserInteractionEnabled = false
        addTarget(self, action: #selector(touchUpInsideHandler(_:)), for: .touchUpInside)
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        embed(containerStackView)
        containerStackView.isLayoutMarginsRelativeArrangement = true

        containerStackView.addArrangedSubview(imageView)
        containerStackView.addArrangedSubview(titleLabel.flexible(axis: .horizontal))
    }

    override open func tintColorDidChange() {
        super.tintColorDidChange()
        
        updateContentIfNeeded()
    }
    
    override open func updateContent() {
        let imageTintСolor: UIColor
        let titleTextColor: UIColor

        if content?.isDestructive == true {
            imageTintСolor = uiConfig.colorPalette.alert
            titleTextColor = imageTintСolor
        } else {
            imageTintСolor = content?.isPrimary == true ? tintColor : uiConfig.colorPalette.inactiveTint
            titleTextColor = uiConfig.colorPalette.text
        }

        titleLabel.text = content?.title
        if isHighlighted {
            titleLabel.textColor = uiConfig.colorPalette.highlightedColorForColor(titleTextColor)
            imageView.image = content?.icon
                .tinted(with: uiConfig.colorPalette.highlightedColorForColor(imageTintСolor))
            backgroundColor = uiConfig.colorPalette.highlightedColorForColor(uiConfig.colorPalette.background)
        } else {
            titleLabel.textColor = titleTextColor
            imageView.image = content?.icon
                .tinted(with: imageTintСolor)
            backgroundColor = uiConfig.colorPalette.background
        }
    }
    
    /// Triggered when `_ChatMessageActionControl` is tapped.
    @objc open func touchUpInsideHandler(_ sender: Any) {
        guard let content = content else { return assertionFailure("Content is unexpectedly nil") }
        content.action(content)
    }
}
