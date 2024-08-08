//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The header view of the poll results table view. By default it displays the poll's name.
open class PollResultsTableHeaderView: _View, ThemeProvider {
    public struct Content {
        public var poll: Poll

        public init(poll: Poll) {
            self.poll = poll
        }
    }

    public var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The main container responsible to render the grey background.
    open private(set) lazy var container = HContainer()

    /// The title label that displays the poll name by default.
    open private(set) lazy var titleLabel = UILabel()
        .withBidirectionalLanguagesSupport
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory

    override open func setUpAppearance() {
        super.setUpAppearance()

        backgroundColor = appearance.colorPalette.background
        container.backgroundColor = appearance.colorPalette.background1
        titleLabel.numberOfLines = 0
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        // Make sure that table header view respects the constraints,
        // since tableView.tableHeaderView does not use constraints.
        // this is need so that the header has dynamic height.
        frame.size = systemLayoutSizeFitting(
            .init(
                width: frame.size.width,
                height: 0
            ),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
    }

    override open func setUpLayout() {
        super.setUpLayout()

        directionalLayoutMargins = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
        container.layoutMargins = .init(top: 16, left: 16, bottom: 16, right: 16)
        container.isLayoutMarginsRelativeArrangement = true
        container.views {
            titleLabel
        }
        container.embedToMargins(in: self)
    }

    override open func updateContent() {
        super.updateContent()

        titleLabel.text = content?.poll.name
    }
}
