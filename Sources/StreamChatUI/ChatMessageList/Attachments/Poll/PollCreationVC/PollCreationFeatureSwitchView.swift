//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import UIKit

/// A view responsible to enable or disable a poll feature.
open class PollCreationFeatureSwitchView: _View, ThemeProvider {
    /// A label to show the name of the feature.
    open private(set) lazy var featureNameLabel = UILabel()
        .withoutAutoresizingMaskConstraints

    /// A view to switch on or off. Used to enable or disable poll features.
    open private(set) lazy var switchView = UISwitch()
        .withoutAutoresizingMaskConstraints

    /// A closure that is triggered whenever the switch value changes.
    public var onValueChange: ((Bool) -> Void)?

    override open func setUp() {
        super.setUp()

        switchView.addTarget(self, action: #selector(switchChangedValue(sender:)), for: .valueChanged)
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        featureNameLabel.font = appearance.fonts.body
    }

    override open func setUpLayout() {
        super.setUpLayout()

        HContainer(spacing: 4, alignment: .center) {
            featureNameLabel
            switchView
        }.embed(in: self)
    }

    @objc open func switchChangedValue(sender: Any?) {
        onValueChange?(switchView.isOn)
    }
}
