//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import UIKit

/// The cell for the poll creation form that displays the name of a feature and the switch button to enable it.
open class PollCreationFeatureCell: _TableViewCell, ThemeProvider {
    public struct Content {
        public var featureName: String

        public init(featureName: String) {
            self.featureName = featureName
        }
    }

    public var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// A view that displays the feature name and the switch to enable/disable the feature.
    open private(set) lazy var featureSwitchView = PollCreationFeatureSwitchView()
        .withoutAutoresizingMaskConstraints

    override open func setUp() {
        super.setUp()

        contentView.isUserInteractionEnabled = true
    }

    override open func setUpLayout() {
        super.setUpLayout()

        addSubview(featureSwitchView)
        featureSwitchView.pin(to: layoutMarginsGuide)
    }

    override open func updateContent() {
        super.updateContent()

        featureSwitchView.featureNameLabel.text = content?.featureName
    }
}
