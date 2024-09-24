//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import UIKit

/// The cell for enabling or disabling a poll feature.
open class PollCreationFeatureCell: _CollectionViewCell, ThemeProvider {
    public struct Content {
        public var feature: PollFeature

        public init(feature: PollFeature) {
            self.feature = feature
        }
    }

    public var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The main container that holds the subviews.
    open private(set) lazy var container = HContainer()

    /// A view that displays the feature name and the switch to enable/disable the feature.
    open private(set) lazy var featureSwitchView = components
        .pollCreationFeatureSwitchView.init()
        .withoutAutoresizingMaskConstraints

    /// A closure that is triggered whenever the switch value changes.
    public var onValueChange: ((Bool) -> Void)?

    override open func setUp() {
        super.setUp()

        contentView.isUserInteractionEnabled = true
        featureSwitchView.onValueChange = { [weak self] newValue in
            self?.onValueChange?(newValue)
        }
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        backgroundColor = appearance.colorPalette.background
        container.backgroundColor = appearance.colorPalette.background1
        container.layer.cornerRadius = 16
    }

    override open func setUpLayout() {
        super.setUpLayout()

        container.views {
            featureSwitchView
        }
        .height(56)
        .layout {
            $0.isLayoutMarginsRelativeArrangement = true
            $0.directionalLayoutMargins = .init(top: 0, leading: 12, bottom: 0, trailing: 12)
        }
        .embed(in: self, insets: .init(top: 6, leading: 12, bottom: 6, trailing: 12))
    }

    override open func updateContent() {
        super.updateContent()

        guard let feature = content?.feature else {
            return
        }

        featureSwitchView.switchView.isOn = feature.isEnabled
        featureSwitchView.featureNameLabel.text = feature.name
    }
}
