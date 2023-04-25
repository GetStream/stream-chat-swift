//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

open class RecordingTipView: _View, ThemeProvider {
    var content: String = L10n.Recording.tip {
        didSet { updateContent() }
    }

    open lazy var container: UIView = .init()
        .withoutAutoresizingMaskConstraints

    open lazy var titleLabel: UILabel = .init()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport

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
    }

    override open func updateContent() {
        super.updateContent()

        titleLabel.text = content
    }
}
