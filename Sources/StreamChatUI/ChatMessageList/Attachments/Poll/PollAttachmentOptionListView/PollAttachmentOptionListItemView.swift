//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The view that displays a poll option in the poll option list view.
open class PollAttachmentOptionListItemView: _View, ThemeProvider {
    public struct Content {
        public var option: PollOption
        public var isVotedByCurrentUser: Bool
        
        public init(option: PollOption, isVotedByCurrentUser: Bool) {
            self.option = option
            self.isVotedByCurrentUser = isVotedByCurrentUser
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

        HContainer(spacing: 3) {
            voteCheckboxButton
            VContainer(spacing: 3) {
                HContainer(spacing: 4) {
                    optionNameLabel
                    Spacer()
                    latestVotesAuthorsView
                    votesCountLabel
                }
                votesProgressView
            }
        }
        .embed(in: self)
    }

    override open func updateContent() {
        super.updateContent()

        guard let content = self.content else {
            return
        }

        optionNameLabel.text = content.option.text
        votesCountLabel.text = "\(content.option.latestVotes.count)"

        if content.isVotedByCurrentUser {
            votesProgressView.setProgress(0.5, animated: true)
            voteCheckboxButton.setCheckedState()
        } else {
            votesProgressView.setProgress(0, animated: true)
            voteCheckboxButton.setUncheckedState()
        }

        latestVotesAuthorsView.content = .init(users: content.option.latestVotes
            .sorted(by: { $0.createdAt > $1.createdAt })
            .compactMap(\.user)
            .suffix(2)
        )
    }

    @objc func didTapOption(sender: Any?) {
        guard let option = content?.option else {
            return
        }
        onOptionTap?(option)
    }
}
