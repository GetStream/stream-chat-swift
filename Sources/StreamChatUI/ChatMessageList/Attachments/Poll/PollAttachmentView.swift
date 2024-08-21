//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The view that displays a poll in the message list.
open class PollAttachmentView: _View, ThemeProvider {
    /// The content data of the poll attachment view.
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

    /// A closure that is triggered whenever the option is tapped either from the button or the item itself.
    public var onOptionTap: ((PollOption) -> Void)?

    /// A closure that is triggered whenever the end poll button is tapped.
    public var onEndTap: ((Poll) -> Void)?

    /// A closure that is triggered whenever the poll results button is tapped.
    public var onResultsTap: ((Poll) -> Void)?

    // MARK: - UI Components

    /// A label which by default displays the title of the Poll.
    open private(set) lazy var pollTitleLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
        .withAccessibilityIdentifier(identifier: "pollTitleLabel")

    /// A label which by default displays the voting state of the Poll.
    open private(set) lazy var pollSubtitleLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
        .withAccessibilityIdentifier(identifier: "pollSubtitleLabel")

    /// A label which by default displays the selection rules of the Poll.
    open private(set) lazy var optionListView: PollAttachmentOptionListView = components
        .pollAttachmentOptionListView.init()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "optionsListView")

    /// The button that when tapped it shows the polls results.
    open private(set) lazy var pollResultsButton = UIButton()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "pollResultsButton")

    /// The button that when tapped it shows the polls results.
    open private(set) lazy var endPollButton = UIButton()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "endPollButton")

    /// The header view composed by the poll title and subtile labels.
    open private(set) lazy var headerView: UIView = {
        VContainer(spacing: 2) {
            pollTitleLabel
            pollSubtitleLabel
        }
    }()

    /// The footer view composed by a stack of buttons that can perform actions on the poll.
    open private(set) lazy var footerView: UIView = {
        VContainer(spacing: 2) {
            pollResultsButton
            endPollButton
        }
    }()

    // MARK: - Lifecycle

    override open func setUp() {
        super.setUp()

        pollResultsButton.addTarget(self, action: #selector(didTapResultsButton(sender:)), for: .touchUpInside)
        endPollButton.addTarget(self, action: #selector(didTapEndPollButton(sender:)), for: .touchUpInside)
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        clipsToBounds = true
        pollTitleLabel.font = appearance.fonts.headlineBold
        pollTitleLabel.numberOfLines = 0
        pollSubtitleLabel.font = appearance.fonts.caption1
        pollSubtitleLabel.textColor = appearance.colorPalette.textLowEmphasis
        pollResultsButton.setTitleColor(appearance.colorPalette.accentPrimary, for: .normal)
        pollResultsButton.titleLabel?.font = appearance.fonts.subheadline.withSize(16)
        endPollButton.setTitleColor(appearance.colorPalette.accentPrimary, for: .normal)
        endPollButton.titleLabel?.font = appearance.fonts.subheadline.withSize(16)
    }

    override open func setUpLayout() {
        super.setUpLayout()

        directionalLayoutMargins = .init(top: 12, leading: 10, bottom: 10, trailing: 12)

        VContainer(spacing: 14) {
            headerView
            optionListView
            footerView
        }
        .embedToMargins(in: self)
    }

    override open func updateContent() {
        super.updateContent()

        guard let content = self.content else {
            return
        }

        pollTitleLabel.text = content.poll.name
        pollSubtitleLabel.text = subtitleText

        optionListView.onOptionTap = onOptionTap
        optionListView.content = .init(poll: content.poll)

        pollResultsButton.setTitle(L10n.Message.Polls.Button.viewResults, for: .normal)
        endPollButton.setTitle(L10n.Message.Polls.Button.endVote, for: .normal)

        let isPollCreatedByCurrentUser = content.poll.createdBy?.id == content.currentUserId
        let shouldShowEndPollButton = !content.poll.isClosed && isPollCreatedByCurrentUser
        endPollButton.isHidden = !shouldShowEndPollButton
    }

    @objc open func didTapResultsButton(sender: Any?) {
        guard let poll = content?.poll else { return }
        onResultsTap?(poll)
    }

    @objc open func didTapEndPollButton(sender: Any?) {
        guard let poll = content?.poll else { return }
        onEndTap?(poll)
    }

    /// The subtitle text. By default it displays the current voting state.
    open var subtitleText: String {
        guard let content = self.content else { return "" }
        let poll = content.poll
        if poll.isClosed == true {
            return L10n.Message.Polls.Subtitle.voteEnded
        } else if poll.enforceUniqueVote == true {
            return L10n.Message.Polls.Subtitle.selectOne
        } else if let maxVotes = poll.maxVotesAllowed, maxVotes > 0 {
            return L10n.Message.Polls.Subtitle.selectUpTo(min(maxVotes, poll.options.count))
        } else {
            return L10n.Message.Polls.Subtitle.selectOneOrMore
        }
    }
}
