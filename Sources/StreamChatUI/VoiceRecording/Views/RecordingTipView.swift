//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

/// A component used to present the user with a tip on how to initiate the
/// recording flow.
open class RecordingTipView: _View, ThemeProvider {
    // MARK: - UI Components

    /// The main container where all components will be added into.
    open lazy var container: UIView = .init()
        .withoutAutoresizingMaskConstraints

    /// The label that shows the prompt message to the user.
    open lazy var titleLabel: UILabel = .init()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport

    // MARK: - Lifecycle

    override open func setUpLayout() {
        super.setUpLayout()

        embed(container)
        container.embed(titleLabel, insets: .init(top: 8, leading: 8, bottom: 8, trailing: 8))
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        backgroundColor = nil
        container.backgroundColor = appearance.colorPalette.border
        titleLabel.font = appearance.fonts.caption1.bold
        titleLabel.textColor = appearance.colorPalette.text
        titleLabel.textAlignment = .center
        titleLabel.text = L10n.Recording.tip
    }
}
