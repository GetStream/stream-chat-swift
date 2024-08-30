//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import UIKit

/// The cell for the poll creation form to configure the multiple votes feature.
open class PollCreationMultipleVotesFeatureCell: _TableViewCell, ThemeProvider {
    /// A view that displays the feature name and the switch to enable/disable the feature.
    open private(set) lazy var featureSwitchView = PollCreationFeatureSwitchView()
        .withoutAutoresizingMaskConstraints

    /// A view to configure the maximum votes per user.
    open private(set) lazy var maximumVotesSwitchView = PollCreationMaximumVotesSwitchView()
        .withoutAutoresizingMaskConstraints

    override open func setUp() {
        super.setUp()

        contentView.isUserInteractionEnabled = true
    }

    override open func setUpLayout() {
        super.setUpLayout()

        VContainer(spacing: 18) {
            featureSwitchView
            maximumVotesSwitchView
        }.embedToMargins(in: self)
    }
}

open class PollCreationMaximumVotesSwitchView: _View, ThemeProvider {
    /// A text field that supports showing validator errors.
    open private(set) lazy var textFieldView = PollCreationTextFieldView()
        .withoutAutoresizingMaskConstraints

    /// A view to switch on or off. Used to enable or disable poll features.
    open private(set) lazy var switchView = UISwitch()
        .withoutAutoresizingMaskConstraints

    override open func setUpLayout() {
        super.setUpLayout()

        HContainer(spacing: 4, alignment: .center) {
            textFieldView
            switchView
        }
        .height(greaterThanOrEqualTo: 45)
        .embed(in: self)
    }
}
