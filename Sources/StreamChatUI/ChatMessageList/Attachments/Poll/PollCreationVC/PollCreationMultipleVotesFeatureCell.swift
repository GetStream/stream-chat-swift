//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import UIKit

/// The cell for the poll creation form to configure the multiple votes feature.
open class PollCreationMultipleVotesFeatureCell: _TableViewCell, ThemeProvider {
    /// The main container that holds the subviews.
    open private(set) lazy var container = VContainer(spacing: 4)

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
                .height(56)
            maximumVotesSwitchView
                .height(56)
        }
        .layout {
            $0.isLayoutMarginsRelativeArrangement = true
            $0.directionalLayoutMargins = .init(top: 0, leading: 12, bottom: 0, trailing: 12)
        }
        .embed(in: self, insets: .init(top: 6, leading: 12, bottom: 6, trailing: 12))
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
        .embed(in: self)
    }
}
