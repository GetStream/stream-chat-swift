//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Button for action displayed in `ChatMessageActionsView`.
open class ChatMessageActionControl: _Control, AppearanceProvider {
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
        .withAccessibilityIdentifier(identifier: "containerStackView")

    /// `UILabel` to show `title`.
    public lazy var titleLabel: UILabel = UILabel()
        .withAccessibilityIdentifier(identifier: "titleLabel")
        .withNumberOfLines(2)

    /// `UIImageView` to show `image`.
    public lazy var imageView: UIImageView = UIImageView()
        .withAccessibilityIdentifier(identifier: "imageView")

    override open func setUpAppearance() {
        super.setUpAppearance()

        titleLabel.font = appearance.fonts.body
        titleLabel.adjustsFontForContentSizeCategory = true
    }

    override open func setUp() {
        super.setUp()

        containerStackView.isUserInteractionEnabled = false
        containerStackView.insetsLayoutMarginsFromSafeArea = false
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
            imageTintСolor = appearance.colorPalette.alert
            titleTextColor = imageTintСolor
        } else {
            imageTintСolor = content?.isPrimary == true ? tintColor : appearance.colorPalette.inactiveTint
            titleTextColor = appearance.colorPalette.text
        }

        titleLabel.text = content?.title
        if isHighlighted {
            titleLabel.textColor = appearance.colorPalette.highlightedColorForColor(titleTextColor)
            imageView.image = content?.icon
                .tinted(with: appearance.colorPalette.highlightedColorForColor(imageTintСolor))
            backgroundColor = appearance.colorPalette.highlightedColorForColor(appearance.colorPalette.background)
        } else {
            titleLabel.textColor = titleTextColor
            imageView.image = content?.icon
                .tinted(with: imageTintСolor)
            backgroundColor = appearance.colorPalette.background
        }
    }
    
    /// Triggered when `ChatMessageActionControl` is tapped.
    @objc open func touchUpInsideHandler(_ sender: Any) {
        guard let content = content else { return log.assertionFailure("Content is unexpectedly nil") }
        content.action(content)
    }
}
