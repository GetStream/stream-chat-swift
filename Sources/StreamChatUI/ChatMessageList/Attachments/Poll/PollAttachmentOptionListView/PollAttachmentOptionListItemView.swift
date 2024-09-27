//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The view that displays a poll option in the poll option list view.
open class PollAttachmentOptionListItemView: _View, ThemeProvider {
    public struct Content {
        /// The option that this view represents.
        public var option: PollOption
        /// The poll that this option belongs.
        public var poll: Poll
        
        public init(option: PollOption, poll: Poll) {
            self.option = option
            self.poll = poll
        }

        /// Whether the current option has been voted by the current user.
        public var isVotedByCurrentUser: Bool {
            poll.hasCurrentUserVoted(for: option)
        }

        /// The number of votes this option has.
        public var voteCount: Int {
            poll.voteCount(for: option)
        }

        /// The ratio of the votes of this option in comparison with the number of total votes.
        public var voteRatio: Float {
            poll.voteRatio(for: option)
        }
    }
    
    public var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    // MARK: - Action Handlers

    /// A closure that is triggered whenever the option is tapped either from the button or the item itself.
    public var onOptionTap: ((PollOption) -> Void)?

    // MARK: - UI Components

    /// A label which displays the name of the option.
    open private(set) lazy var optionNameLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
        .withAccessibilityIdentifier(identifier: "optionNameLabel")

    /// A label which displays the number of votes of the option.
    open private(set) lazy var votesCountLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
        .withAccessibilityIdentifier(identifier: "votesCountLabel")

    /// A progress view that displays the number of votes this option
    /// has in relation with the option with max votes.
    open private(set) lazy var votesProgressView = UIProgressView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "votesProgressView")

    /// A button to add or remove a vote for this option.
    open private(set) lazy var voteCheckboxButton = CheckboxButton(type: .roundedRect)
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "voteCheckboxView")

    /// The avatar view type used to build the avatar views displayed on the vote authors.
    open lazy var latestVotesAuthorsView = StackedUserAvatarsView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "latestVotesAuthorsView")

    // MARK: - Lifecycle

    override open func setUp() {
        super.setUp()

        voteCheckboxButton.addTarget(self, action: #selector(didTapOption(sender:)), for: .touchUpInside)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapOption(sender:)))
        addGestureRecognizer(tapGestureRecognizer)
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        optionNameLabel.numberOfLines = 0
        optionNameLabel.font = appearance.fonts.subheadline
        votesCountLabel.font = appearance.fonts.body.withSize(14)
        votesCountLabel.textColor = appearance.colorPalette.text
        voteCheckboxButton.contentEdgeInsets = .zero
        voteCheckboxButton.imageEdgeInsets = .zero
        voteCheckboxButton.titleEdgeInsets = .zero
    }

    override open func setUpLayout() {
        super.setUpLayout()

        votesCountLabel.setContentCompressionResistancePriority(.streamRequire, for: .horizontal)

        HContainer(spacing: 2) {
            voteCheckboxButton
                .width(25)
            VContainer(spacing: 4) {
                HContainer(spacing: 4, alignment: .top) {
                    optionNameLabel
                    Spacer()
                    latestVotesAuthorsView
                    votesCountLabel
                }
                votesProgressView
            }
            .height(greaterThanOrEqualTo: 28)
        }
        .embed(in: self)
    }

    override open func updateContent() {
        super.updateContent()

        guard let content = self.content else {
            return
        }

        optionNameLabel.text = content.option.text
        votesCountLabel.text = "\(content.voteCount)"
        
        latestVotesAuthorsView.content = .init(users: latestVotesAuthors)
        latestVotesAuthorsView.isHidden = content.poll.votingVisibility == .anonymous

        if content.isVotedByCurrentUser {
            voteCheckboxButton.setCheckedState()
        } else {
            voteCheckboxButton.setUncheckedState()
        }
        voteCheckboxButton.isHidden = content.poll.isClosed

        if content.poll.isOptionWinner(content.option) {
            votesProgressView.tintColor = appearance.colorPalette.alternativeActiveTint
        } else {
            votesProgressView.tintColor = appearance.colorPalette.accentPrimary
        }
        votesProgressView.progress = content.voteRatio
    }

    @objc func didTapOption(sender: Any?) {
        guard let option = content?.option else {
            return
        }
        onOptionTap?(option)
    }

    /// Whether the poll is closed and this option is the winner.
    open var isOptionWinner: Bool {
        guard let content = self.content else { return false }
        return content.poll.isOptionWinner(content.option)
    }

    /// The authors of the latest votes of this option.
    open var latestVotesAuthors: [ChatUser] {
        content?.option.latestVotes
            .prefix(2)
            .compactMap(\.user) ?? []
    }
}
