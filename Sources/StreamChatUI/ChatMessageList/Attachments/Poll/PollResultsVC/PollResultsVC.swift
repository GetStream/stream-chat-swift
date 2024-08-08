//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view controller that shows the results of a poll.
open class PollResultsVC:
    _ViewController,
    ThemeProvider,
    PollControllerDelegate,
    UITableViewDelegate {
    /// The table view responsible to display the poll results.
    open private(set) lazy var tableView = UITableView(frame: .zero, style: .grouped)
        .withoutAutoresizingMaskConstraints

    public var pollController: PollController

    public init(pollController: PollController) {
        self.pollController = pollController
        super.init(nibName: nil, bundle: nil)
    }

    open private(set) lazy var dataSource = UITableViewDiffableDataSource<PollOption, PollVote>(
        tableView: self.tableView
    ) { [weak self] tableView, indexPath, pollVote in
        let option = self?.pollController.poll?.options[indexPath.section]
        let cell = tableView.dequeueReusableCell(with: PollResultsItemCell.self, for: indexPath)
        cell.backgroundColor = tableView.backgroundColor
        cell.content = .init(vote: pollVote)
        if indexPath.row == (option?.latestVotes.count ?? 0) - 1 || indexPath.row > 5 {
            cell.itemView.layer.cornerRadius = 16
            cell.itemView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        } else {
            cell.itemView.layer.cornerRadius = 0
            cell.itemView.layer.maskedCorners = []
        }
        return cell
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func setUp() {
        super.setUp()

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: appearance.images.close,
            style: .done,
            target: self,
            action: #selector(didTapCloseButton(sender:))
        )
        navigationItem.leftBarButtonItem?.tintColor = appearance.colorPalette.background7

        tableView.register(PollResultsItemCell.self)
        tableView.dataSource = dataSource
        tableView.delegate = self
        pollController.synchronize()
        pollController.delegate = self
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        title = "Poll Results" // TODO: Local
        tableView.allowsSelection = false
        tableView.backgroundColor = appearance.colorPalette.background
        tableView.separatorStyle = .none
        tableView.estimatedSectionHeaderHeight = 40
        dataSource.defaultRowAnimation = .fade
    }

    override open func setUpLayout() {
        super.setUpLayout()

        view.embed(tableView)
        tableView.tableHeaderView = {
            let view = UIView()
            let label = UILabel().withoutAutoresizingMaskConstraints
            label.text = pollController.poll?.name
            view.embed(label)
            return view
        }()
    }

    @objc open func didTapCloseButton(sender: Any?) {
        dismiss(animated: true)
    }

    /// Applies data source changes to the table view based on the current poll controller data.
    open func updateDataSource() {
        var snapshot = NSDiffableDataSourceSnapshot<PollOption, PollVote>()
        snapshot.appendSections(pollController.poll?.options ?? [])
        pollController.poll?.options.forEach {
            snapshot.appendItems(
                $0.latestVotes.sorted(by: { $0.createdAt < $1.createdAt }).suffix(5),
                toSection: $0
            )
        }

        dataSource.apply(snapshot, animatingDifferences: true)
    }

    // MARK: - UITableViewDelegate

    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let poll = pollController.poll else { return nil }
        let option = poll.options[section]
        let view = PollResultsItemHeaderView()
        view.content = .init(option: option, voteCount: poll.voteCount(for: option))
        return view
    }

    open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let option = pollController.poll?.options[section],
              option.latestVotes.count > 5 else {
            return UIView()
        }
        let button = UIButton(type: .roundedRect)
        button.setTitle("Show More", for: .normal)
        return button
    }

    open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let option = pollController.poll?.options[section],
              option.latestVotes.count > 5 else {
            return 8
        }

        return UITableView.automaticDimension
    }

    // MARK: - PollControllerDelegate

    open func pollController(_ pollController: PollController, didUpdatePoll poll: EntityChange<Poll>) {
        updateDataSource()
    }

    open func pollController(
        _ pollController: PollController,
        didUpdateCurrentUserVotes votes: [ListChange<PollVote>]
    ) {
        // no-op
    }
}

open class PollResultsItemCell: _TableViewCell, ThemeProvider {
    public struct Content {
        public var vote: PollVote

        public init(vote: PollVote) {
            self.vote = vote
        }
    }

    public var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    open private(set) lazy var itemView: PollVoteItemView = PollVoteItemView()
        .withoutAutoresizingMaskConstraints

    override open func setUpLayout() {
        super.setUpLayout()

        embed(itemView, insets: .init(top: 0, leading: 16, bottom: 0, trailing: 16))
    }

    override open func updateContent() {
        guard let content = self.content else { return }
        itemView.content = .init(vote: content.vote)
    }
}

open class PollVoteItemView: _View, ThemeProvider {
    public struct Content {
        public var vote: PollVote

        public init(
            vote: PollVote
        ) {
            self.vote = vote
        }
    }

    public var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    open private(set) lazy var authorAvatarView: ChatUserAvatarView = components
        .userAvatarView.init()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var authorNameLabel = UILabel()
        .withBidirectionalLanguagesSupport
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory

    open private(set) lazy var voteTimestampLabel = UILabel()
        .withBidirectionalLanguagesSupport
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory

    override open func setUpAppearance() {
        super.setUpAppearance()

        backgroundColor = appearance.colorPalette.background1
        authorAvatarView.shouldShowOnlineIndicator = false
        authorNameLabel.font = appearance.fonts.body
        authorNameLabel.textColor = appearance.colorPalette.text
        voteTimestampLabel.font = appearance.fonts.footnote
        voteTimestampLabel.textColor = appearance.colorPalette.textLowEmphasis
    }

    override open func setUpLayout() {
        super.setUpLayout()

        directionalLayoutMargins = .init(top: 0, leading: 12, bottom: 0, trailing: 12)

        HContainer(spacing: 4, alignment: .center) {
            authorAvatarView
                .width(20)
                .height(20)
            authorNameLabel
            Spacer()
            voteTimestampLabel
        }
        .height(greaterThanOrEqualTo: 40)
        .embedToMargins(in: self)
    }

    override open func updateContent() {
        authorAvatarView.content = content?.vote.user
        authorNameLabel.text = content?.vote.user?.name
        if #available(iOS 15.0, *) {
            voteTimestampLabel.text = content?.vote.createdAt.formatted(.dateTime)
        } else {
            // Fallback on earlier versions
        }
    }
}

open class PollResultsItemHeaderView: _View, ThemeProvider {
    public struct Content {
        public var option: PollOption
        public var voteCount: Int

        public init(option: PollOption, voteCount: Int) {
            self.option = option
            self.voteCount = voteCount
        }
    }

    public var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    open private(set) var container: UIStackView?

    open private(set) lazy var optionNameLabel = UILabel()
        .withBidirectionalLanguagesSupport
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory

    open private(set) lazy var votesLabel = UILabel()
        .withBidirectionalLanguagesSupport
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory

    override open func setUpAppearance() {
        super.setUpAppearance()

        backgroundColor = appearance.colorPalette.background
        optionNameLabel.numberOfLines = 0
        optionNameLabel.font = appearance.fonts.headlineBold
        optionNameLabel.textColor = appearance.colorPalette.text
        votesLabel.font = appearance.fonts.footnote
        votesLabel.textColor = appearance.colorPalette.text
    }

    override open func setUpLayout() {
        super.setUpLayout()

        directionalLayoutMargins = .init(top: 0, leading: 16, bottom: 0, trailing: 16)

        container = HContainer(spacing: 4, alignment: .center) {
            optionNameLabel
                .height(greaterThanOrEqualTo: 25)
            Spacer()
            votesLabel.layout {
                $0.setContentCompressionResistancePriority(.streamRequire, for: .horizontal)
            }
        }
        .embedToMargins(in: self)

        container?.isLayoutMarginsRelativeArrangement = true
        container?.layoutMargins = .init(top: 12, left: 12, bottom: 12, right: 12)
        container?.backgroundColor = appearance.colorPalette.background1
    }

    override open func updateContent() {
        super.updateContent()

        guard let content = self.content else { return }

        updateBorders()

        optionNameLabel.text = content.option.text
        votesLabel.text = "\(content.voteCount) Votes" // : Local
    }

    open func updateBorders() {
        guard let content = self.content else { return }

        if !content.option.latestVotes.isEmpty {
            container?.layer.cornerRadius = 16
            container?.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else {
            container?.layer.cornerRadius = 16
            container?.layer.maskedCorners = .all
        }
    }
}
