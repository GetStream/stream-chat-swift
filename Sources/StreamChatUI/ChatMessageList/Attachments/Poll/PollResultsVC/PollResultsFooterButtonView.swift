//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The poll results footer view for each section.
open class PollResultsFooterButtonView: _TableHeaderFooterView, ThemeProvider {
    /// The bottom spacing of the footer.
    public var bottomSpacing: CGFloat = 8

    /// A closure that is trigger when the button is tapped.
    public var onTap: (() -> Void)?

    /// The container that holds the button action.
    open lazy var container = HContainer(alignment: .center)

    /// The button that is displayed on the footer of poll results.
    open private(set) lazy var actionButton: UIButton = UIButton(type: .system)
        .withoutAutoresizingMaskConstraints

    override open func setUp() {
        super.setUp()

        actionButton.addTarget(self, action: #selector(didTapButton(sender:)), for: .touchUpInside)
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        actionButton.setTitle(L10n.Message.Polls.Button.showAll, for: .normal)
        actionButton.setTitleColor(appearance.colorPalette.accentPrimary, for: .normal)
        actionButton.titleLabel?.font = appearance.fonts.subheadline
    }

    override open func setUpLayout() {
        super.setUpLayout()

        container.isLayoutMarginsRelativeArrangement = true
        container.directionalLayoutMargins = .init(top: 8, leading: 0, bottom: 8, trailing: 0)
        container.views {
            actionButton
        }
        .embed(in: self, insets: .init(top: 0, leading: 16, bottom: bottomSpacing, trailing: 16))
    }

    @objc open func didTapButton(sender: Any?) {
        onTap?()
    }
}
