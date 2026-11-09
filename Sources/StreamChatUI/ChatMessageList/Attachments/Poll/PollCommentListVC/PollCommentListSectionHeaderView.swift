//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The poll comment list section header view. By default it displays the comment text.
open class PollCommentListSectionHeaderView: _TableHeaderFooterView, ThemeProvider {
    public struct Content {
        public var comment: PollVote
        /// The language to show the comment in, when it has a translation to it.
        /// If `nil`, the original comment is shown.
        public var translationLanguage: TranslationLanguage?

        public init(
            comment: PollVote,
            translationLanguage: TranslationLanguage? = nil
        ) {
            self.comment = comment
            self.translationLanguage = translationLanguage
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
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport

    override open func setUpAppearance() {
        super.setUpAppearance()

        commentLabel.numberOfLines = 0
        commentLabel.font = appearance.fonts.headlineBold
        commentLabel.textColor = appearance.colorPalette.textPrimary
    }

    override open func setUpLayout() {
        super.setUpLayout()

        container.views {
            commentLabel
        }
        .padding(top: 12, leading: 12, bottom: 0, trailing: 12)
        .embed(in: self, insets: .init(top: 0, leading: 16, bottom: 0, trailing: 16))
    }

    override open func updateContent() {
        super.updateContent()

        commentLabel.text = content.flatMap { $0.comment.answerText(in: $0.translationLanguage) }
    }
}
