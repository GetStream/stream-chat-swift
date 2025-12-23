//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatCommonUI
import UIKit

/// The footer view of the poll comment list table view. By default it displays the button add or update a comment.
open class PollCommentListTableFooterView: _View, ThemeProvider {
    public struct Content {
        public var poll: Poll
        public var currentUserId: UserId

        public init(poll: Poll, currentUserId: UserId) {
            self.poll = poll
            self.currentUserId = currentUserId
        }
    }

    public var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// A closure that is trigger when the button is tapped.
    public var onTap: (() -> Void)?

    /// The main container responsible to render the grey background.
    open private(set) lazy var container = HContainer()

    /// The button to add a comment to the poll.
    open private(set) lazy var actionButton = UIButton(type: .system)
        .withoutAutoresizingMaskConstraints

    override open func setUp() {
        super.setUp()

        actionButton.addTarget(self, action: #selector(didTapButton(sender:)), for: .touchUpInside)
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        actionButton.tintColor = appearance.colorPalette.accentPrimary
        actionButton.titleLabel?.font = appearance.fonts.bodyBold
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

        directionalLayoutMargins = .init(top: 0, leading: 16, bottom: 0, trailing: 16)
        container.directionalLayoutMargins = .init(top: 12, leading: 0, bottom: 12, trailing: 0)
        container.isLayoutMarginsRelativeArrangement = true
        container.views {
            actionButton
        }
        container.embedToMargins(in: self)
    }

    override open func updateContent() {
        super.updateContent()

        guard let content = self.content else { return }

        let currentUserHasAnswer = content.poll.latestAnswers
            .contains(where: { $0.user?.id == content.currentUserId })

        if currentUserHasAnswer {
            actionButton.setTitle(L10n.Polls.updateComment, for: .normal)
        } else {
            actionButton.setTitle(L10n.Polls.addComment, for: .normal)
        }
    }

    @objc open func didTapButton(sender: Any?) {
        onTap?()
    }
}
