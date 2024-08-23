//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The poll comment list section header view. By default it displays the comment text.
open class PollCommentListSectionHeaderView: _TableHeaderFooterView, ThemeProvider {
    public struct Content {
        public var comment: PollVote

        public init(
            comment: PollVote
        ) {
            self.comment = comment
        }
    }

    public var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The container responsible to layout the subviews.
    open private(set) lazy var container = HContainer()

    /// The label that displays the comment text.
    open private(set) lazy var commentLabel = UILabel()
        .withoutAutoresizingMaskConstraints

    override open func setUpAppearance() {
        super.setUpAppearance()

        commentLabel.numberOfLines = 0
        commentLabel.font = appearance.fonts.headlineBold
        commentLabel.textColor = appearance.colorPalette.text
    }

    override open func setUpLayout() {
        super.setUpLayout()

        container.layout {
            $0.isLayoutMarginsRelativeArrangement = true
            $0.directionalLayoutMargins = .init(top: 12, leading: 12, bottom: 6, trailing: 12)
        }
        .views {
            commentLabel
        }
        .embed(in: self, insets: .init(top: 0, leading: 16, bottom: 0, trailing: 16))
    }

    override open func updateContent() {
        super.updateContent()

        commentLabel.text = content?.comment.answerText
    }
}
