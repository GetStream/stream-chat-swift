//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The cell separator reusable view that acts as container of the visible part of the separator view.
open class CellSeparatorReusableView: _CollectionReusableView, AppearanceProvider {
    /// The visible part of separator view.
    open lazy var separatorView = UIView().withoutAutoresizingMaskConstraints

    override open func setUpAppearance() {
        super.setUpAppearance()
        backgroundColor = .clear
        separatorView.backgroundColor = appearance.colorPalette.border
    }

    override open func setUpLayout() {
        embed(separatorView)
    }
}
