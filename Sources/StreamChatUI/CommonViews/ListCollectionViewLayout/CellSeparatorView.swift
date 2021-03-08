//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The cell separator reusable view that acts as container of the visible part of the separator view.
public typealias CellSeparatorReusableView = _CellSeparatorReusableView<NoExtraData>

/// The cell separator reusable view that acts as container of the visible part of the separator view.
open class _CellSeparatorReusableView<ExtraData: ExtraDataTypes>: _CollectionReusableView, UIConfigProvider {
    /// The visible part of separator view.
    open lazy var separatorView = UIView().withoutAutoresizingMaskConstraints

    override public func defaultAppearance() {
        super.defaultAppearance()
        backgroundColor = .clear
        separatorView.backgroundColor = uiConfig.colorPalette.border
    }

    override open func setUpLayout() {
        embed(separatorView)
    }
}
